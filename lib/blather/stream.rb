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
  #     client = Blather::Stream.start MyClient.new, "jid@domain/res", "pass"
  #     client.write "[pure xml over the wire]"
  class Stream < EventMachine::Connection
    class NoConnection < RuntimeError; end

    STREAM_NS = 'http://etherx.jabber.org/streams'
    attr_accessor :password
    attr_reader :jid

    # Start the stream between client and server
    #
    # @param [Object] client an object that will respond to #post_init,
    # #unbind #receive_data
    # @param [Blather::JID, #to_s] jid the jid to authenticate with
    # @param [String] pass the password to authenticate with
    # @param [String, nil] host the hostname or IP to connect to. Default is
    # to use the domain on the JID
    # @param [Fixnum, nil] port the port to connect on. Default is the XMPP
    # default of 5222
    def self.start(client, jid, pass, host = nil, port = 5222)
      jid = JID.new jid
      if host
        connect host, port, self, client, jid, pass
      else
        require 'resolv'
        srv = []
        Resolv::DNS.open do |dns|
          srv = dns.getresources(
            "_xmpp-client._tcp.#{jid.domain}",
            Resolv::DNS::Resource::IN::SRV
          )
        end

        if srv.empty?
          connect jid.domain, port, self, client, jid, pass
        else
          srv.sort! do |a,b|
            (a.priority != b.priority) ? (a.priority <=> b.priority) :
                                         (b.weight <=> a.weight)
          end

          srv.detect do |r|
            not connect(r.target.to_s, r.port, self, client, jid, pass) === false
          end
        end
      end
    end

    # Attempt a connection
    # Stream will raise +NoConnection+ if it receives #unbind before #post_init
    # this catches that and returns false prompting for another attempt
    # @private
    def self.connect(host, port, conn, client, jid, pass)
      EM.connect host, port, conn, client, jid, pass
    rescue NoConnection
      false
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
      Blather.logger.debug "SENDING: (#{caller[1]}) #{stanza}"
      send_data stanza.respond_to?(:to_xml) ? stanza.to_xml : stanza.to_s
    end

    # Called by EM.connect to initialize stream variables
    # @private
    def initialize(client, jid, pass)
      super()

      @error = nil
      @receiver = @client = client

      self.jid = jid
      @to = self.jid.domain
      @password = pass
    end

    # Called when EM completes the connection to the server
    # this kicks off the starttls/authorize/bind process
    # @private
    def connection_completed
#      @keepalive = EM::PeriodicTimer.new(60) { send_data ' ' }
      start
    end

    # Called by EM with data from the wire
    # @private
    def receive_data(data)
      Blather.logger.debug "\n#{'-'*30}\n"
      Blather.logger.debug "STREAM IN: #{data}"
      @parser << data

    rescue ParseError => e
      @error = e
      send "<stream:error><xml-not-well-formed xmlns='#{StreamError::STREAM_ERR_NS}'/></stream:error>"
      stop
    end

    # Called by EM after the connection has started
    # @private
    def post_init
      @connected = true
    end

    # Called by EM when the connection is closed
    # @private
    def unbind
      raise NoConnection unless @connected

#      @keepalive.cancel
      @state = :stopped
      @client.receive_data @error if @error
      @client.unbind
    end

    # Called by the parser with parsed nodes
    # @private
    def receive(node)
      Blather.logger.debug "RECEIVING (#{node.element_name}) #{node}"
      @node = node

      if @node.namespace && @node.namespace.prefix == 'stream'
        case @node.element_name
        when 'stream'
          @state = :ready if @state == :stopped
          return
        when 'error'
          handle_stream_error
          return
        when 'end'
          stop
          return
        when 'features'
          @state = :negotiating
          @receiver = Features.new(
            self,
            proc { ready! },
            proc { |err| @error = err; stop }
          )
        end
      end
      @receiver.receive_data @node.to_stanza
    end

    # Ensure the JID gets attached to the client
    # @private
    def jid=(new_jid)
      Blather.logger.debug "NEW JID: #{new_jid}"
      @jid = JID.new new_jid
    end

  protected
    # Stop the stream
    # @private
    def stop
      unless @state == :stopped
        @state = :stopped
        send '</stream:stream>'
      end
    end

    # @private
    def handle_stream_error
      @error = StreamError.import(@node)
      stop
    end

    # @private
    def ready!
      @state = :started
      @receiver = @client
      @client.post_init self, @jid
    end
  end  # Stream

end  # Blather
