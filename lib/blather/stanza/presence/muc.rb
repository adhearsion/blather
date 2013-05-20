module Blather
class Stanza
class Presence

  class MUC < Status
    register :muc_join, :x, "http://jabber.org/protocol/muc"

    def self.new(*args)
      new_node = super
      new_node.muc
      new_node
    end

    module InstanceMethods
      def inherit(node)
        muc.remove
        super
        self
      end

      def muc
        unless muc = at_xpath('ns:x', :ns => MUC.registered_ns)
          self << (muc = XMPPNode.new('x', self.document))
          muc.namespace = self.class.registered_ns
        end
        muc
      end
    end

    include InstanceMethods
  end # MUC

end # Presence
end # Stanza
end # Blather
