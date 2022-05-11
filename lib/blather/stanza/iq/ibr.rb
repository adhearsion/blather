module Blather
class Stanza
class Iq

  # # In-Band Registration
  #
  # [XEP-0077: In-Band Registration](https://xmpp.org/extensions/xep-0077.html)
  #
  # @handler :ibr
  class IBR < Query
    register :ibr, nil, "jabber:iq:register"

    def registered=(reg)
      query.at_xpath("./ns:registered", ns: self.class.registered_ns)&.remove
      node = Nokogiri::XML::Node.new("registered", document)
      node.default_namespace = self.class.registered_ns
      query << node if reg
    end

    def registered?
      !!query.at_xpath("./ns:registered", ns: self.class.registered_ns)
    end

    def remove!
      query.children.remove
      node = Nokogiri::XML::Node.new("remove", document)
      node.default_namespace = self.class.registered_ns
      query << node
    end

    def remove?
      !!query.at_xpath("./ns:remove", ns: self.class.registered_ns)
    end

    def form
      X.find_or_create(query)
    end

    [
      "instructions",
      "username",
      "nick",
      "password",
      "name",
      "first",
      "last",
      "email",
      "address",
      "city",
      "state",
      "zip",
      "phone",
      "url",
      "date"
    ].each do |tag|
      define_method("#{tag}=") do |v|
        query.at_xpath("./ns:#{tag}", ns: self.class.registered_ns)&.remove
        node = Nokogiri::XML::Node.new(tag, document)
        node.default_namespace = self.class.registered_ns
        node.content = v
        query << node
      end

      define_method(tag) do
        query.at_xpath("./ns:#{tag}", ns: self.class.registered_ns)&.content
      end
    end
  end

end #Iq
end #Stanza
end
