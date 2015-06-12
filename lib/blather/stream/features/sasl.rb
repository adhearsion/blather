module Blather
class Stream

  # @private
  class SASL < Features
    class UnknownMechanism < BlatherError
      register :sasl_unknown_mechanism
    end

    MECHANISMS = %w[
      digest-md5
      plain
      anonymous
    ].freeze

    SASL_NS = 'urn:ietf:params:xml:ns:xmpp-sasl'.freeze
    register SASL_NS

    def initialize(stream, succeed, fail)
      super
      @jid = @stream.jid
      @pass = @stream.password
      @authcid = @stream.authcid
      @mechanisms = []
    end

    def receive_data(stanza)
      @node = stanza
      case stanza.element_name
      when 'mechanisms'
        available_mechanisms = stanza.children.map { |m| m.content.downcase }
        @mechanisms = MECHANISMS.select { |m| available_mechanisms.include? m }
        next!
      when 'failure'
        next!
      when 'success'
        @stream.start
      else
        if self.respond_to?(stanza.element_name)
          self.__send__(stanza.element_name)
        else
          fail! UnknownResponse.new(stanza)
        end
      end
    end

  protected
    def next!
      if @jid.node == ''
        process_anonymous
      else
        @idx = @idx ? @idx+1 : 0
        authenticate_with @mechanisms[@idx]
      end
    end

    def process_anonymous
      if @mechanisms.include?('anonymous')
        authenticate_with 'anonymous'
      else
        fail! BlatherError.new('The server does not support ANONYMOUS login. You must provide a node in the JID')
      end
    end

    def authenticate_with(method)
      method = case method
      when 'digest-md5' then  DigestMD5
      when 'plain'      then  Plain
      when 'anonymous'  then  Anonymous
      when nil          then  fail!(SASLError.import(@node))
      else                    next!
      end

      if method.is_a?(Module)
        extend method
        authenticate
      end
    end

    ##
    # Base64 Encoder
    def b64(str)
      [str].pack('m').gsub(/\s/,'')
    end

    ##
    # Builds a standard auth node
    def auth_node(mechanism, content = nil)
      node = XMPPNode.new 'auth'
      node.content = content if content
      node.namespace = SASL_NS
      node[:mechanism] = mechanism
      node
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
        Blather.log "CHALLENGE DECODE: #{res.inspect}"

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
        node.namespace = SASL_NS

        unless @initial_response_sent
          @initial_response_sent = true
          @response = {
            :nonce        => @nonce,
            :charset      => 'utf-8',
            :username     => @authcid,
            :realm        => @realm || @jid.domain,
            :cnonce       => h(Time.new.to_f.to_s),
            :nc           => '00000001',
            :qop          => 'auth',
            :'digest-uri' => "xmpp/#{@jid.domain}",
          }
          @response[:response] = generate_response
          @response.each { |k,v| @response[k] = "\"#{v}\"" unless [:nc, :qop, :response, :charset].include?(k) }

          Blather.log "CHALLENGE RESPONSE: #{@response.inspect}"
          Blather.log "CH RESP TXT: #{@response.map { |k,v| "#{k}=#{v}" } * ','}"

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

    # @private
    module Plain
      def authenticate
        @stream.send auth_node('PLAIN', b64("#{@jid.stripped}\x00#{@authcid}\x00#{@pass}"))
      end
    end #Plain

    # @private
    module Anonymous
      def authenticate
        @stream.send auth_node('ANONYMOUS')
      end
    end #Anonymous
  end #SASL

end #Stream
end
