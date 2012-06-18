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
        error_node = stanza.xpath('//error').first

        if error_node
          fail!(error_node)
        elsif stanza['type'] == 'result' && (stanza.content.empty? || !stanza.children.find { |v| v.element_name == "query" }.nil?)
          succeed!
        else
          @stream.send register_node
        end
      end

      def register_node
        node = Blather::Stanza::Iq::Query.new(:set)
        query_node = node.xpath('//query').first
        query_node['xmlns'] = 'jabber:iq:register'
        username_node = Nokogiri::XML::Node.new('username', node)
        username_node.content = @jid.node
        password_node = Nokogiri::XML::Node.new('password', node)
        password_node.content = @pass
        query_node.add_child(username_node)
        query_node.add_child(password_node)
        node
      end
    end
  end
end
