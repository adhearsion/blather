module Blather
  module Stream
    class Parser
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
        puts "PARSING: #{string}" if @@debug
        if string == '</stream:stream>'
          @receiver.receive XMPPNode.new('stream:end')
        else
          @parser.string = string
          @parser.parse
        end
      end

      def on_start_element(elem, attrs)
        puts "START ELEM: (#{[elem, attrs].inspect})" if @@debug
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
        puts "CHARS: #{chars}" if @@debug
        @current << XML::Node.new_text(chars) if @current
      end

      def on_cdata_block(block)
        puts "CDATA: #{block}" if @@debug
        @current << XML::Node.new_cdata(block) if @current
      end

      def on_end_element(elem)
        puts "END ELEM: (#{@current.parent}) #{elem}" if @@debug
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