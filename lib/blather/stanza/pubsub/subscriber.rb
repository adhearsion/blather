module Blather
class Stanza
class PubSub

  module Subscriber
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def subscribe(host, node, jid)
        stanza = self.new(:set, host)
        subscription = XMPPNode.new 'subscription'
        subscription.attributes[:node] = node
        subscription.attributes[:jid] = JID.new(jid).stripped
        stanza.pubsub << subscription
        stanza
      end

      def unsubscribe(host, node, jid, subid = nil)
        stanza = self.new(:set, host)
        unsubscription = XMPPNode.new 'unsubscribe'
        unsubscription.attributes[:node] = node
        unsubscription.attributes[:jid] = JID.new(jid).stripped
        unsubscription.attributes[:subid] = subid
        stanza.pubsub << unsubscription
        stanza
      end
    end

    module InstanceMethods
      def subscription
        if sub = subscription?
          { :node         => sub.attributes[:node],
            :jid          => JID.new(sub.attributes[:jid]),
            :subid        => sub.attributes[:subid],
            :subscription => sub.attributes[:subscription] }
        end
      end

      def subscription?
        find_first('//pubsub_ns:pubsub/pubsub_ns:subscription', :pubsub_ns => self.ns)
      end

      def unsubscribe
        if sub = unsubscribe?
          { :node => sub.attributes[:node],
            :jid  => JID.new(sub.attributes[:jid]) }
        end
      end

      def unsubscribe?
        find_first('//pubsub_ns:pubsub/pubsub_ns:unsubscribe', :pubsub_ns => self.class.ns)
      end
    end

  end #Subscriber

end #PubSub
end #Stanza
end #Blather
