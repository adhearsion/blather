module Blather
  module Stream
    class TLS
      def initialize(stream)
        @stream = stream
        @callbacks = {
          'starttls'  => proc { @stream.send "<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>" },
          'proceed'   => proc { @stream.start_tls; @callbacks['success'].call },
          'success'   => proc { },
          'failure'   => proc { }
        }
      end

      def success(&callback)
        @callbacks['success'] = callback
      end

      def failure(&callback)
        @callbacks['failure'] = callback
      end

      def receive(node)
        @callbacks[node.element_name].call if @callbacks[node.element_name]
      end
    end
  end
end