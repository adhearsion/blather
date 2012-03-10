require 'cgi'
module Blather
  class Stream
    class SASL < Features
      module XFacebookPlatform

        # Lets the server know we're going to try X-FACEBOOK-PLATFORM authentication
        def authenticate
          client = @stream.client
          unless client.respond_to?(:app_id) and client.respond_to?(:access_token)
            raise "Client must respond to :app_id and :access_token"
          end
          @stream.send auth_node('X-FACEBOOK-PLATFORM')
        end

        # Receive the challenge command.
        def challenge
          @challenge = decode_challenge
          respond
        end

        private
        def decode_challenge
          rv = CGI.parse(Base64.decode64(@node.content))
          rv.each { |k,v| rv[k] = v[0] if v.is_a?(Array) }
          Blather.log "CHALLENGE DECODE: #{rv.inspect}"
          rv
        end

        # Send challenge response
        def respond
          node = XMPPNode.new 'response'
          node.namespace = SASL_NS

          unless @initial_response_sent
            @initial_response_sent = true
            access_token = @stream.client.access_token
            app_id = @stream.client.app_id
            response = {
              'access_token' => access_token,
              'api_key' => app_id,
              'call_id' => Time.now.tv_sec,
              'method' => @challenge['method'],
              'nonce' => @challenge['nonce'],
              'v' => '1.0'
            }

            Blather.log "CHALLENGE RESPONSE: #{response.inspect}"

            query = response.collect do |key, value|
              "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
            end.sort.join('&')
            node.content = Base64.strict_encode64(query)
          end

          @stream.send node
        end

      end #XFacebookPlatform
    end
  end
end