module Blather
  module Stream
    class Parser
      STREAM_REGEX = %r{(/)?stream:stream}.freeze

      @@debug = false
      def self.debug; @@debug; end
      def self.debug=(debug); @@debug = debug; end

      include XML::SaxParser::Callbacks

      def initialize(receiver)
        @receiver = receiver
        @current = nil

        @parser = XML::SaxParser.new
        @parser.callbacks = self
      end

      def parse(string)
        LOG.debug "PARSING: #{string}" if @@debug
        if string =~ STREAM_REGEX && $1
          @receiver.receive XMPPNode.new('stream:end')
        else
          string << "</stream:stream>" if string =~ STREAM_REGEX && !$1

          @parser.string = string
          @parser.parse
        end
      end

      def on_start_element(elem, attrs)
        LOG.debug "START ELEM: (#{[elem, attrs].inspect})" if @@debug
        e = XMPPNode.new elem
        attrs.each { |n,v| e[n] = v }

        if elem == 'stream:stream'
          @receiver.receive e

        elsif !@receiver.stopped?
          @current << e if @current
          @current = e

        end
      end

      def on_characters(chars = '')
        LOG.debug "CHARS: #{chars}" if @@debug
        @current << XML::Node.new_text(chars) if @current
      end

      def on_cdata_block(block)
        LOG.debug "CDATA: #{block}" if @@debug
        @current << XML::Node.new_cdata(block) if @current
      end

      def on_end_element(elem)
        return if elem =~ STREAM_REGEX

        LOG.debug "END ELEM: (#{@current}) #{elem}" if @@debug
        if @current.parent?
          @current = @current.parent

        else
          c, @current = @current, nil
          @receiver.receive c

        end
      end
    end
  end
end