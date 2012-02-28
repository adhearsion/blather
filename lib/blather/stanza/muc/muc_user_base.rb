module Blather
class Stanza
class MUC

  module MUCUserBase
    def self.included(klass)
      klass.extend ClassMethods
      klass.register :muc_user, :x, "http://jabber.org/protocol/muc#user"
    end

    module ClassMethods
      def new(*args)
        super.tap { |e| e.muc_user }
      end
    end

    def inherit(node)
      muc_user.remove
      super
      self
    end

    def password
      find_password_node && password_node.content
    end

    def password=(var)
      password_node.content = var
    end

    def muc_user
      unless muc_user = find_first('ns:x', :ns => self.class.registered_ns)
        self << (muc_user = XMPPNode.new('x', self.document))
        muc_user.namespace = self.class.registered_ns
      end
      muc_user
    end

    def password_node
      unless pw = find_password_node
        muc_user << (pw = XMPPNode.new('password', self.document))
      end
      pw
    end

    def find_password_node
      muc_user.find_first 'ns:password', :ns => self.class.registered_ns
    end
  end # MUCUserBase

end # MUC
end # Stanza
end # Blather
