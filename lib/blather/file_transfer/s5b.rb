module Blather
  class FileTransfer
    # SOCKS5 Bytestreams Transfer helper
    # Takes care of accepting, declining and offering file transfers through the stream
    class S5b

      # Set this to false if you don't want to fallback to In-Band Bytestreams
      attr_accessor :allow_ibb_fallback

      # Set this to true if the buddies of your bot will be in the same local network
      #
      # Usually IM clients advertise all network addresses which they can determine.
      # Skipping the local ones can save time if your bot is not in the same local network as it's buddies
      attr_accessor :allow_private_ips

      def initialize(stream, iq)
        @stream = stream
        @iq = iq
        @allow_ibb_fallback = true
        @allow_private_ips = false
      end

      # Accept an incoming file-transfer
      #
      # @param [module] handler the handler for incoming data, see Blather::FileTransfer::SimpleFileReceiver for an example
      # @param [Array] params the params to be passed into the handler
      def accept(handler, *params)
        @streamhosts = @iq.streamhosts
        @streamhosts.delete_if {|s| begin IPAddr.new(s.host).private? rescue false end } unless @allow_private_ips
        @socket_address = Digest::SHA1.hexdigest("#{@iq.sid}#{@iq.from}#{@iq.to}")

        @handler = handler
        @params = params

        connect_next_streamhost
        @stream.clear_handlers :s5b_open, :from => @iq.from
      end

      # Decline an incoming file-transfer
      def decline
        @stream.clear_handlers :s5b_open, :from => @iq.from
        @stream.write StanzaError.new(@iq, 'not-acceptable', :auth).to_node
      end

      # Offer a file to somebody, not implemented yet
      def offer
        # TODO: implement
      end

      private

      def connect_next_streamhost
        if streamhost = @streamhosts.shift
          connect(streamhost)
        else
          if @allow_ibb_fallback
            @stream.register_handler :ibb_open, :from => @iq.from, :sid => @iq.sid do |iq|
              transfer = Blather::FileTransfer::Ibb.new(@stream, iq)
              transfer.accept(@handler, *@params)
              true
            end
          end

          @stream.write StanzaError.new(@iq, 'item-not-found', :cancel).to_node
        end
      end

      def connect(streamhost)
        begin
          socket = EM.connect streamhost.host, streamhost.port, SocketConnection, @socket_address, 0, @handler, *@params

          socket.callback do
            answer = @iq.reply
            answer.streamhosts = nil
            answer.streamhost_used = streamhost.jid

            @stream.write answer
          end

          socket.errback do
            connect_next_streamhost
          end
        rescue EventMachine::ConnectionError => e
          connect_next_streamhost
        end
      end

      # @private
      class SocketConnection < EM::P::Socks5
        include EM::Deferrable

        def initialize(host, port, handler, *params)
          super(host, port)
          @@handler = handler
          @params = params
        end

        def post_init
          self.succeed
          
          class << self
            include @@handler
          end
          send(:initialize, *@params)
          post_init
        end

        def unbind
          self.fail if @socks_state != :connected
        end
      end
    end
  end
end
