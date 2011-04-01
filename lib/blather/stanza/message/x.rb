module Blather
class Stanza
module MUC
module Message

  class X < XMPPNode
    register :x, "http://jabber.org/protocol/muc#user"

    def self.import(node)
      klass = nil
      node.at('//ns:x', :ns => registered_ns).children.detect do |e|
        klass = class_from_registration(e.element_name, registered_ns)
        puts [:x, e, klass]
        klass
      end

      klass.import(node) if klass && klass != self
    end
  end

end
end
end
end
