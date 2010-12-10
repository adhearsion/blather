require "base64"

module Blather
  class FileTransfer
    # In-Band Bytestreams Transfer helper
    # Takes care of accepting, declining and offering file transfers through the stream
    class Ibb
      def initialize(stream, iq)
        @stream = stream
        @iq = iq
        @seq = 0
      end

      # Accept an incoming file-transfer
      #
      # @param [module] handler the handler for incoming data, see Blather::FileTransfer::SimpleFileReceiver for an example
      # @param [Array] params the params to be passed into the handler
      def accept(handler, *params)
        @io_read, @io_write = IO.pipe
        EM::attach @io_read, handler, *params

        @stream.register_handler :ibb_data, :from => @iq.from, :sid => @iq.sid do |iq|
          if iq.data['seq'] == @seq.to_s
            begin
              @io_write << Base64.decode64(iq.data.content)

              @stream.write iq.reply

              @seq += 1
              @seq = 0 if @seq > 65535
            rescue Errno::EPIPE => e
              @stream.write StanzaError.new(iq, 'not-acceptable', :cancel).to_node
            end
          else
            @stream.write StanzaError.new(iq, 'unexpected-request', :wait).to_node
          end
          true
        end

        @stream.register_handler :ibb_close, :from => @iq.from, :sid => @iq.sid do |iq|
          @stream.write iq.reply
          @stream.clear_handlers :ibb_data, :from => @iq.from, :sid => @iq.sid
          @stream.clear_handlers :ibb_close, :from => @iq.from, :sid => @iq.sid

          @io_write.close
          true
        end

        @stream.clear_handlers :ibb_open, :from => @iq.from
        @stream.clear_handlers :ibb_open, :from => @iq.from, :sid => @iq.sid
        @stream.write @iq.reply
      end

      # Decline an incoming file-transfer
      def decline
        @stream.clear_handlers :ibb_open, :from => @iq.from
        @stream.clear_handlers :ibb_data, :from => @iq.from, :sid => @iq.sid
        @stream.clear_handlers :ibb_close, :from => @iq.from, :sid => @iq.sid
        @stream.write StanzaError.new(@iq, 'not-acceptable', :cancel).to_node
      end

      # Offer a file to somebody, not implemented yet
      def offer
        # TODO: implement
      end
    end
  end
end