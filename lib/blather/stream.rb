require 'celluloid/io'
require 'resolv'

module Blather

  # # A pure XMPP stream.
  #
  # Blather::Stream can be used to build your own handler system if Blather's
  # doesn't suit your needs. It will take care of the entire connection
  # process then start sending Stanza objects back to the registered client.
  #
  # The client you register with Blather::Stream needs to implement the following
  # methods:
  # * #post_init(stream, jid = nil)
  #   Called after the stream has been initiated.
  #   @param [Blather::Stream] stream is the connected stream object
  #   @param [Blather::JID, nil] jid is the full JID as recognized by the server
  #
  # * #receive_data(stanza)
  #   Called every time the stream receives a new stanza
  #   @param [Blather::Stanza] stanza a stanza object from the server
  #
  # * #unbind
  #   Called when the stream is shutdown. This will be called regardless of which
  #   side shut the stream down.
  #
  # @example Create a new stream and handle it with our own class
  #     class MyClient
  #       attr :jid
  #
  #       def post_init(stream, jid = nil)
  #         @stream = stream
  #         self.jid = jid
  #         p "Stream Started"
  #       end
  #
  #       # Pretty print the stream
  #       def receive_data(stanza)
  #         pp stanza
  #       end
  #
  #       def unbind
  #         p "Stream Ended"
  #       end
  #
  #       def write(what)
  #         @stream.write what
  #       end
  #     end
  #
  #     client = Blather::Stream.new MyClient.new, "jid@domain/res", "pass"
  #     client.run!
  #     client.write "[pure xml over the wire]"
  class Stream
    include Celluloid::IO

    # Connection not found
    class NoConnection < RuntimeError; end
    class ConnectionFailed < RuntimeError; end
    class ConnectionTimeout < RuntimeError; end

    # @private
    STREAM_NS = 'http://etherx.jabber.org/streams'
    attr_reader :jid, :password, :host, :port, :logger

    def self.start(*args)
      self.new(*args).run!
    end

    def initialize(client, jid, password, host = nil, port = nil, certs_directory = nil, connect_timeout = nil, logger = Logger)
      @receiver = @client = client
      self.jid = jid
      @password, @host, @logger = password, host, logger
      @port = port || 5222
      @connect_timeout = connect_timeout || 180
      @cert_store = CertStore.new(certs_directory) if certs_directory
      @error = nil
      logger.debug "Starting up..."
    end

    def run
      @parser = Parser.new current_actor
      @inited = true
      connection_targets(jid).detect do |host, port|
        attempt_connection host, port
      end
      connection_established
      loop { receive_data @socket.readpartial(4096) }
    rescue EOFError, IOError => e
      logger.info "Client socket closed due to (#{e.class}) #{e.message}!"
      terminate
    end

    [:started, :stopped, :ready, :negotiating].each do |state|
      define_method("#{state}?") { @state == state }
    end

    # Send data over the wire
    #
    # @todo Queue if not ready
    #
    # @param [#to_xml, #to_s] stanza the stanza to send over the wire
    def send(stanza)
      data = stanza.respond_to?(:to_xml) ? stanza.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML) : stanza.to_s
      Blather.log "SENDING: (#{caller[1]}) #{stanza}"
      send_data data
    end

    # Ensure the JID gets attached to the client
    # @private
    def jid=(new_jid)
      Blather.log "USING JID: #{new_jid}"
      @jid = JID.new new_jid
    end

    def finalize
      # raise NoConnection unless @inited
      # raise ConnectionFailed unless @connected

      # @connect_timer.cancel if @connect_timer
      # @keepalive.cancel
      # @state = :stopped
      @client.unbind
    end

    def cleanup
      @parser.finish
      @connect_timer.cancel if @connect_timer
    end

    # Called by the parser with parsed nodes
    # @private
    def receive(node)
      Blather.log "RECEIVING (#{node.element_name}) #{node}"

      if node.namespace && node.namespace.prefix == 'stream'
        case node.element_name
        when 'stream'
          @state = :ready if @state == :stopped
          return
        when 'error'
          @client.receive_data StreamError.import(node)
          stop
          return
        when 'end'
          stop
          return
        when 'features'
          @state = :negotiating
          @receiver = Features.new(
            self,
            proc { ready },
            proc { |err|
              @client.receive_data err
              stop
            }
          )
        end
      end
      @receiver.receive_data node.to_stanza
    end

    private

    # Stop the stream
    # @private
    def stop(error = nil)
      unless @state == :stopped
        @state = :stopped
        send "#{error}</stream:stream>"
      end
    end

    # @private
    def ready
      @state = :started
      @receiver = @client
      @client.post_init self, @jid
    end

    def connection_targets(jid)
      return [[host, port]] if host && port

      srv = []
      Resolv::DNS.open do |dns|
        srv = dns.getresources(
          "_xmpp-client._tcp.#{jid.domain}",
          Resolv::DNS::Resource::IN::SRV
        )
      end

      return [[jid.domain, port]] if srv.empty?

      srv.sort! do |a,b|
        (a.priority != b.priority) ? (a.priority <=> b.priority) :
                                     (b.weight <=> a.weight)
      end

      srv.map { |r| [r.target.to_s, r.port] }
    end

    # Attempt a connection
    # Stream will raise +NoConnection+ if it receives #unbind before #post_init
    # this catches that and returns false prompting for another attempt
    # @private
    def attempt_connection(host, port)
      logger.info "Attempting connection to #{host}:#{port}"
      @socket = TCPSocket.from_ruby_socket ::TCPSocket.new(host, port)
    rescue Errno::ECONNREFUSED, SocketError => e
      logger.error "Connection failed due to #{e.class}. Trying the next option."
      false
    end

    # This kicks off the starttls/authorize/bind process
    # @private
    def connection_established
      # if @connect_timeout
      #   @connect_timer = EM::Timer.new @connect_timeout do
      #     raise ConnectionTimeout, "Stream timed out after #{@connect_timeout} seconds." unless started?
      #   end
      # end
      # @connected = true
      # @keepalive = EM::PeriodicTimer.new(60) { send_data ' ' }
      start
    end

    def send_data(data)
      @socket.write data
    end

    # @private
    def receive_data(data)
      @parser << data
    rescue ParseError => e
      @client.receive_data e
      send "<stream:error><xml-not-well-formed xmlns='#{StreamError::STREAM_ERR_NS}'/></stream:error>"
      stop
    end

    # # Called by EM to verify the peer certificate. If a certificate store directory
    # # has not been configured don't worry about peer verification. At least it is encrypted
    # # We Log the certificate so that you can add it to the trusted store easily if desired
    # # @private
    # def ssl_verify_peer(pem)
    #   # EM is supposed to close the connection when this returns false,
    #   # but it only does that for inbound connections, not when we
    #   # make a connection to another server.
    #   Blather.log "Checking SSL cert: #{pem}"
    #   return true if !@@store
    #   @@store.trusted?(pem).tap do |trusted|
    #     close_connection unless trusted
    #   end
    # end
  end  # Stream

end  # Blather
