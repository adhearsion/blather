module Blather # :nodoc:
module Stream # :nodoc:

  class SASL # :nodoc:
    class UnknownMechanism < BlatherError
      handler_heirarchy ||= []
      handler_heirarchy << :unknown_mechanism
    end

    SASL_NS = 'urn:ietf:params:xml:ns:xmpp-sasl'

    def initialize(stream, jid, pass = nil)
      @stream = stream
      @jid = jid
      @pass = pass
      @callbacks = {}
      @mechanism = 0
      @mechanisms = []

      init_callbacks
    end

    def init_callbacks
      @callbacks['mechanisms'] = proc {
        @mechanisms = @node.children
        authenticate if set_mechanism
      }
    end

    def set_mechanism
      mod = case (mechanism = @mechanisms[@mechanism].content)
      when 'DIGEST-MD5' then DigestMD5
      when 'PLAIN'      then Plain
      when 'ANONYMOUS'  then Anonymous
      else
        @stream.send "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><invalid-mechanism/></failure>"
        @callbacks['failure'].call UnknownMechanism.new("Unknown SASL mechanism (#{mechanism})")
        return false
      end

      extend mod
      true
    end

    def receive(node)
      @node = node
      if @node.element_name == 'failure'
        if @mechanisms[@mechanism += 1]
          set_mechanism
          authenticate
        else
          @callbacks['failure'].call(@node)
        end
      else
        @callbacks[@node.element_name].call if @callbacks[@node.element_name]
      end
    end

    def success(&callback)
      @callbacks['success'] = callback
    end

    def failure(&callback)
      @callbacks['failure'] = callback
    end

  protected
    def b64(str)
      [str].pack('m').gsub(/\s/,'')
    end

    def auth_node(mechanism, content = nil)
      node = XMPPNode.new 'auth', content
      node['xmlns'] = SASL_NS
      node['mechanism'] = mechanism
      node
    end

    module DigestMD5 # :nodoc:
      def self.extended(obj)
        obj.instance_eval { @callbacks['challenge'] = proc { decode_challenge; respond } }
      end

      def authenticate
        @stream.send auth_node('DIGEST-MD5')
      end

    private
      def decode_challenge
        text = @node.content.unpack('m').first
        res = {}

        text.split(',').each do |statement|
          key, value = statement.split('=')
          res[key] = value.delete('"') unless key.empty?
        end
        LOG.debug "CHALLENGE DECODE: #{res.inspect}"

        @nonce ||= res['nonce']
        @realm ||= res['realm']
      end

      def generate_response
        a1 = "#{d("#{@response[:username]}:#{@response[:realm]}:#{@pass}")}:#{@response[:nonce]}:#{@response[:cnonce]}"
        a2 = "AUTHENTICATE:#{@response[:'digest-uri']}"
        h("#{h(a1)}:#{@response[:nonce]}:#{@response[:nc]}:#{@response[:cnonce]}:#{@response[:qop]}:#{h(a2)}")
      end

      def respond
        node = XMPPNode.new 'response'
        node['xmlns'] = SASL_NS

        unless @initial_response_sent
          @initial_response_sent = true
          @response = {
            :nonce        => @nonce,
            :charset      => 'utf-8',
            :username     => @jid.node,
            :realm        => @realm || @jid.domain,
            :cnonce       => h(Time.new.to_f.to_s),
            :nc           => '00000001',
            :qop          => 'auth',
            :'digest-uri' => "xmpp/#{@jid.domain}",
          }
          @response[:response] = generate_response
          @response.each { |k,v| @response[k] = "\"#{v}\"" unless [:nc, :qop, :response, :charset].include?(k) }

          LOG.debug "CHALLENGE RESPOSNE: #{@response.inspect}"
          LOG.debug "CH RESP TXT: #{@response.map { |k,v| "#{k}=#{v}" } * ','}"

          # order is to simplify testing
          order = [:nonce, :charset, :username, :realm, :cnonce, :nc, :qop, :'digest-uri', :response]
          node.content = b64(order.map { |k| v = @response[k]; "#{k}=#{v}" } * ',')
        end

        @stream.send node
      end

      def d(s); Digest::MD5.digest(s);    end
      def h(s); Digest::MD5.hexdigest(s); end
    end #DigestMD5

    module Plain # :nodoc:
      def authenticate
        @stream.send auth_node('PLAIN', b64("#{@jid.stripped}\x00#{@jid.node}\x00#{@pass}"))
      end
    end #Plain

    module Anonymous # :nodoc:
      def authenticate
        @stream.send auth_node('ANONYMOUS', b64(@jid.node))
      end
    end #Anonymous

  end #SASL

end #Stream
end
