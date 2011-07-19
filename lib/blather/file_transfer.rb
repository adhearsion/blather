module Blather
  # File Transfer helper
  # Takes care of accepting, declining and offering file transfers through the stream
  class FileTransfer

    # Set this to false if you don't want to use In-Band Bytestreams
    attr_accessor :allow_ibb

    # Set this to false if you don't want to use SOCKS5 Bytestreams
    attr_accessor :allow_s5b

    # Set this to true if you want SOCKS5 Bytestreams to attempt to use private network addresses
    attr_accessor :allow_private_ips
    
    # Create a new FileTransfer
    #
    # @param [Blather::Stream] stream the stream the file transfer should use
    # @param [Blather::Stanza::Iq::Si] iq a si iq used to stream-initiation
    def initialize(stream, iq = nil)
      @stream = stream
      @allow_s5b = true
      @allow_ibb = true

      @iq = iq
    end

    # Accept an incoming file-transfer
    #
    # @param [module] handler the handler for incoming data, see Blather::FileTransfer::SimpleFileReceiver for an example
    # @param [Array] params the params to be passed into the handler
    def accept(handler, *params)
      answer = @iq.reply

      answer.si.feature.x.type = :submit

      supported_methods = @iq.si.feature.x.field("stream-method").options.map(&:value)
      if supported_methods.include?(Stanza::Iq::S5b::NS_S5B) and @allow_s5b
        answer.si.feature.x.fields = {:var => 'stream-method', :value => Stanza::Iq::S5b::NS_S5B}

        @stream.register_handler :s5b_open, :from => @iq.from do |iq|
          transfer = Blather::FileTransfer::S5b.new(@stream, iq)
          transfer.allow_ibb_fallback = true if @allow_ibb
          transfer.allow_private_ips = true if @allow_private_ips
          transfer.accept(handler, *params)
          true
        end

        @stream.write answer
      elsif supported_methods.include?(Stanza::Iq::Ibb::NS_IBB) and @allow_ibb
        answer.si.feature.x.fields = {:var => 'stream-method', :value => Stanza::Iq::Ibb::NS_IBB}

        @stream.register_handler :ibb_open, :from => @iq.from do |iq|
          transfer = Blather::FileTransfer::Ibb.new(@stream, iq)
          transfer.accept(handler, *params)
          true
        end

        @stream.write answer
      else
        reason = XMPPNode.new('no-valid-streams')
        reason.namespace = Blather::Stanza::Iq::Si::NS_SI

        @stream.write StanzaError.new(@iq, 'bad-request', 'cancel', nil, [reason]).to_node
      end
    end

    # Decline an incoming file-transfer
    def decline
      answer = StanzaError.new(@iq, 'forbidden', 'cancel', 'Offer declined').to_node

      @stream.write answer
    end

    # Offer a file to somebody, not implemented yet
    def offer
      # TODO: implement
    end

    # Simple handler for incoming file transfers
    #
    # You can define your own handler and pass it to the accept method.
    module SimpleFileReceiver
      def initialize(path, size)
        @path = path
        @size = size
        @transferred = 0
      end

      # @private
      def post_init
        @file = File.open(@path, "w")
      end

      # @private
      def receive_data(data)
        @transferred += data.size
        @file.write data
      end

      # @private
      def unbind
        @file.close
        File.delete(@path) unless @transferred == @size
      end
    end
  end
end
