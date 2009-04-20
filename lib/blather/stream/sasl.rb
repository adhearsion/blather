module Blather # :nodoc:
class Stream # :nodoc:

  class SASL < StreamHandler # :nodoc:
    class UnknownMechanism < BlatherError
      handler_heirarchy ||= []
      handler_heirarchy << :unknown_mechanism
    end

    SASL_NS = 'urn:ietf:params:xml:ns:xmpp-sasl'.freeze

    def initialize(stream, jid, pass = nil)
      super stream
      @jid = jid
      @pass = pass
      @mechanism_idx = 0
      @mechanisms = []
    end

    def set_mechanism
      mod = case (mechanism = @mechanisms[@mechanism_idx].content)
      when 'DIGEST-MD5' then DigestMD5
      when 'PLAIN'      then Plain
      when 'ANONYMOUS'  then Anonymous
      else
        # Send a failure node and kill the stream
        @stream.send "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><invalid-mechanism/></failure>"
        @failure.call UnknownMechanism.new("Unknown SASL mechanism (#{mechanism})")
        return false
      end

      extend mod
      true
    end

    ##
    # Handle incoming nodes
    # Cycle through possible mechanisms until we either
    # run out of them or none work
    def handle(node)
      if node.element_name == 'failure'
        if @mechanisms[@mechanism_idx += 1]
          set_mechanism
          authenticate
        else
          failure node
        end
      else
        super
      end
    end

  protected
    def failure(node = nil)
      @failure.call SASLError.import(node)
    end

    ##
    # Base64 Encoder
    def b64(str)
      [str].pack('m').gsub(/\s/,'')
    end

    ##
    # Builds a standard auth node
    def auth_node(mechanism, content = nil)
      node = XMPPNode.new 'auth', content
      node['xmlns'] = SASL_NS
      node['mechanism'] = mechanism
      node
    end

    ##
    # Respond to the <mechanisms> node sent by the server
    def mechanisms
      @mechanisms = @node.children
      authenticate if set_mechanism
    end

    ##
    # Digest MD5 authentication
    module DigestMD5 # :nodoc:
      ##
      # Lets the server know we're going to try DigestMD5 authentication
      def authenticate
        @stream.send auth_node('DIGEST-MD5')
      end

      ##
      # Receive the challenge command.
      def challenge
        decode_challenge
        respond
      end

    private
      ##
      # Decodes digest strings 'foo=bar,baz="faz"'
      # into {'foo' => 'bar', 'baz' => 'faz'}
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

      ##
      # Builds the properly encoded challenge response
      def generate_response
        a1 = "#{d("#{@response[:username]}:#{@response[:realm]}:#{@pass}")}:#{@response[:nonce]}:#{@response[:cnonce]}"
        a2 = "AUTHENTICATE:#{@response[:'digest-uri']}"
        h("#{h(a1)}:#{@response[:nonce]}:#{@response[:nc]}:#{@response[:cnonce]}:#{@response[:qop]}:#{h(a2)}")
      end

      ##
      # Send challenge response
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
          # Ruby 1.9 eliminates the need for this with ordered hashes
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
