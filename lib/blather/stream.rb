module Blather

  class Stream < EventMachine::Connection
    STREAM_NS = 'http://etherx.jabber.org/streams'
    ##
    # Start the stream between client and server
    #   [client] must be an object that will respond to #call and #jid=
    #   [jid] must be a valid argument for JID.new (see JID)
    #   [pass] must be the password
    #   [host] (optional) must be the hostname or IP to connect to. defaults to the domain of [jid]
    #   [port] (optional) must be the port to connect to. defaults to 5222
    def self.start(client, jid, pass, host = nil, port = 5222)
      jid = JID.new jid
      host ||= jid.domain

      EM.connect host, port, self, client, jid, pass
    end

    ##
    # Send data over the wire
    #   The argument for this can be anything that
    #   responds to #to_s
    def send(stanza)
      #TODO Queue if not ready
      LOG.debug "SENDING: (#{caller[1]}) #{stanza}"
      send_data stanza.respond_to?(:to_xml) ? stanza.to_xml : stanza.to_s
    end

    ##
    # True if the stream is in the stopped state
    def stopped?
      @state == :stopped
    end

    ##
    # True when the stream is in the negotiation phase.
    def negotiating?
      ![:stopped, :ready].include? @state
    end

    ##
    # True when the stream is ready
    #   The stream is ready immediately after receiving <stream:stream>
    #   and before any feature negotion. Once feature negoation starts
    #   the stream will not be ready until all negotations have completed
    #   successfully.
    def ready?
      @state == :ready
    end

    ##
    # Called by EM.connect to initialize stream variables
    def initialize(client, jid, pass) # :nodoc:
      super()

      @error = nil
      @client = client

      self.jid = jid
      @pass = pass

      @to = @jid.domain
    end

    ##
    # Called when EM completes the connection to the server
    # this kicks off the starttls/authorize/bind process
    def connection_completed # :nodoc:
#      @keepalive = EM::Timer.new(60) { send_data ' ' }
      @state = :stopped
      dispatch
    end

    ##
    # Called by EM with data from the wire
    def receive_data(data) # :nodoc:
      LOG.debug "\n#{'-'*30}\n"
      LOG.debug "<< #{data}"
      @parser.receive_data data

    rescue ParseWarning => e
      @client.receive_data e
    rescue ParseError => e
      @error = e
      send "<stream:error><xml-not-well-formed xmlns='urn:ietf:params:xml:ns:xmpp-streams'/></stream:error>"
      stop
    end

    ##
    # Called by EM when the connection is closed
    def unbind # :nodoc:
#      @keepalive.cancel
      @state = :stopped
      @client.receive_data @error if @error
      @client.unbind
    end

    ##
    # Called by the parser with parsed nodes
    def receive(node) # :nodoc:
      LOG.debug "RECEIVING (#{node.element_name}) #{node}"
      @node = node

      if @node.find_first('//stream:error', :stream => 'http://etherx.jabber.org/streams')
        handle_stream_error
        return
      end

      case @node.element_name
      when 'stream'
        @state = :ready if @state == :stopped

      when 'stream:end'
        stop

      when 'features'
        @features = @node.children
        @state = :features
        dispatch

      else
        dispatch

      end
    end

    ##
    # Ensure the JID gets attached to the client
    def jid=(new_jid) # :nodoc:
      LOG.debug "NEW JID: #{new_jid}"
      @jid = JID.new new_jid
      @client.jid = @jid
    end

  protected
    ##
    # Dispatch based on current state
    def dispatch
      __send__ @state
    end

    ##
    # Start the stream
    #   Each time the stream is started or re-started we need to kill off the old
    #   parser so as not to confuse it
    def start
    end

    ##
    # Stop the stream
    def stop
      unless @state == :stopped
        @state = :stopped
        send '</stream:stream>'
      end
    end

    ##
    # Called when @state == :stopped to start the stream
    #   Counter intuitive, I know
    def stopped
      start
    end

    ##
    # Called when @state == :ready
    #   Simply passes the stanza to the client
    def ready
      @client.receive_data @node.to_stanza
    end

    def handle_stream_error
      @error = StreamError.import @node
      stop
      @state = :error
    end

    ##
    # Called when @state == :features
    #   Runs through the list of features starting each one in turn
    def features
      feature = @features.first
      LOG.debug "FEATURE: #{feature}"
      @state = case feature ? feature.namespace.href : nil
      when 'urn:ietf:params:xml:ns:xmpp-tls'      then :establish_tls
      when 'urn:ietf:params:xml:ns:xmpp-sasl'     then :authenticate_sasl
      when 'urn:ietf:params:xml:ns:xmpp-bind'     then :bind_resource
      when 'urn:ietf:params:xml:ns:xmpp-session'  then :establish_session
      else :ready
      end

      # Dispatch to the individual feature methods unless
      # feature negotiation is complete
      dispatch unless ready?
    end

    ##
    # Start TLS
    def establish_tls
      unless @tls
        @tls = TLS.new self
        # on success destroy the TLS object and restart the stream
        @tls.on_success { LOG.debug "TLS: SUCCESS"; @tls = nil; start }
        # on failure stop the stream
        @tls.on_failure { |err| LOG.debug "TLS: FAILURE"; @error = err; stop }

        @node = @features.shift
      end
      @tls.handle @node
    end

    ##
    # Authenticate via SASL
    def authenticate_sasl
      unless @sasl
        @sasl = SASL.new(self, @jid, @pass)
        # on success destroy the SASL object and restart the stream
        @sasl.on_success { LOG.debug "SASL SUCCESS"; @sasl = nil; start }
        # on failure set the error and stop the stream
        @sasl.on_failure { |err| LOG.debug "SASL FAIL"; @error = err; stop }

        @node = @features.shift
      end
      @sasl.handle @node
    end

    ##
    # Bind to the resource provided by either the client or the server
    def bind_resource
      unless @resource
        @resource = Resource.new self, @jid
        # on success destroy the Resource object, set the jid, continue along the features dispatch process
        @resource.on_success { |jid| LOG.debug "RESOURCE: SUCCESS"; @resource = nil; self.jid = jid; @state = :features; dispatch }
        # on failure end the stream
        @resource.on_failure { |err| LOG.debug "RESOURCE: FAILURE"; @error = err; stop }

        @node = @features.shift
      end
      @resource.handle @node
    end

    ##
    # Establish the session between client and server
    def establish_session
      unless @session
        @session = Session.new self, @to
        # on success destroy the session object, let the client know the stream has been started
        # then continue the features dispatch process
        @session.on_success { LOG.debug "SESSION: SUCCESS"; @session = nil; @client.post_init; @state = :features; dispatch }
        # on failure end the stream
        @session.on_failure { |err| LOG.debug "SESSION: FAILURE"; @error = err; stop }

        @node = @features.shift
      end
      @session.handle @node
    end
  end

end
