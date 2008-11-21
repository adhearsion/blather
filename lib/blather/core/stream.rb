module Blather

  module Stream

    # Connect to the server
    def self.start(client, jid, pass, host = nil, port = 5222)
      jid = JID.new jid
      host ||= jid.domain

      EM.connect host, port, self, client, jid, pass
    end

    def initialize(client, jid, pass)
      super()

      @client = client

      self.jid = jid
      @pass = pass

      @to = @jid.domain
      @id = nil
      @lang = 'en'
      @version = '1.0'
      @namespace = 'jabber:client'

      @parser = Parser.new self
    end

    def connection_completed
#      @keepalive = EM::Timer.new(60) { send_data ' ' }
      @state = :stopped
      dispatch
    end

    def receive_data(data)
      @parser.parse data

    rescue => e
      @client.respond_to?(:rescue) ? @client.rescue(e) : raise(e)
    end

    def unbind
#      @keepalive.cancel
      @state == :stopped
    end

    def receive(node)
      LOG.debug "\n"+('-'*30)+"\n"
      LOG.debug "RECEIVING (#{node.element_name}) #{node}"
      @node = node

      case @node.element_name
      when 'stream:stream'
        @state = :ready if @state == :stopped

      when 'stream:end'
        @state = :stopped

      when 'stream:features'
        @features = @node.children
        @state = :features
        dispatch

      when 'stream:error'
        raise StreamError.new(@node)

      else
        dispatch

      end
    end

    def send(stanza)
      #TODO Queue if not ready
      LOG.debug "SENDING: (#{caller[1]}) #{stanza}"
      send_data stanza.to_s
    end

    def stopped?
      @state == :stopped
    end

    def ready?
      @state == :ready
    end

    def jid=(new_jid)
      LOG.debug "NEW JID: #{new_jid}"
      new_jid = JID.new new_jid
      @client.jid = new_jid
      @jid = new_jid
    end

  private
    def dispatch
      __send__ @state
    end

    def start
      send <<-STREAM
        <stream:stream
          to='#{@to}'
          xmlns='#{@namespace}'
          xmlns:stream='http://etherx.jabber.org/streams'
          version='#{@version}'
          xml:lang='#{@lang}'
        >
      STREAM
    end

    def stop
      send '</stream:stream>'
    end

    def stopped
      start
    end

    def ready
      @client.call @node.to_stanza
    end

    def features
      feature = @features.first
      LOG.debug "FEATURE: #{feature}"
      @state = case feature ? feature['xmlns'] : nil
      when 'urn:ietf:params:xml:ns:xmpp-tls'      then :establish_tls
      when 'urn:ietf:params:xml:ns:xmpp-sasl'     then :authenticate_sasl
      when 'urn:ietf:params:xml:ns:xmpp-bind'     then :bind_resource
      when 'urn:ietf:params:xml:ns:xmpp-session'  then :establish_session
      else :ready
      end

      dispatch unless ready?
    end

    def establish_tls
      unless @tls
        @tls = TLS.new self
        @tls.success { LOG.debug "TLS: SUCCESS"; @tls = nil; start }
        @tls.failure { LOG.debug "TLS: FAILURE"; stop }
        @node = @features.shift
      end
      @tls.receive @node
    end

    def authenticate_sasl
      unless @sasl
        @sasl = SASL.new(self, @jid, @pass)
        @sasl.success { LOG.debug "SASL SUCCESS"; @sasl = nil; start }
        @sasl.failure { LOG.debug "SASL FAIL"; stop }
        @node = @features.shift
      end
      @sasl.receive @node
    end

    def bind_resource
      unless @resource
        @resource = Resource.new self, @jid
        @resource.success { |jid| LOG.debug "RESOURCE: SUCCESS"; @resource = nil; self.jid = jid; @state = :features; dispatch }
        @resource.failure { LOG.debug "RESOURCE: FAILURE"; stop }
        @node = @features.shift
      end
      @resource.receive @node
    end

    def establish_session
      unless @session
        @session = Session.new self, @to
        @session.success { LOG.debug "SESSION: SUCCESS"; @session = nil; @client.stream_started(self); @state = :features; dispatch }
        @session.failure { LOG.debug "SESSION: FAILURE"; stop }
        @node = @features.shift
      end
      @session.receive @node
    end
  end

end
