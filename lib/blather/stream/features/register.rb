module Blather
  class Stream
    class Register < Features
      REGISTER_NS = "http://jabber.org/features/iq-register".freeze

      register REGISTER_NS

      def initialize(stream, succeed, fail)
        super
        @jid = @stream.jid
        @pass = @stream.password
      end

      def receive_data(stanza)
        error_node = stanza.xpath("//error").first

        if error_node
          fail!(BlatherError.new(stanza))
        elsif stanza['type'] == 'result' && (stanza.content.empty? || stanza.children.find { |v| v.element_name == "query" })
          succeed!
        else
          @stream.send register_query
        end
      end

      def register_query
        node = Blather::Stanza::Iq::Query.new(:set)
        query_node = node.xpath('//query').first
        query_node['xmlns'] = 'jabber:iq:register'
        Nokogiri::XML::Builder.with(query_node) do |xml|
          xml.username @jid.node
          xml.password @pass
        end
        node
      end
    end
  end
end
