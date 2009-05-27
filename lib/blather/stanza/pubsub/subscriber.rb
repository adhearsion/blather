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
        subscription[:node] = node
        subscription[:jid] = JID.new(jid).stripped
        stanza.pubsub << subscription
        stanza
      end

      def unsubscribe(host, node, jid, subid = nil)
        stanza = self.new(:set, host)
        unsubscription = XMPPNode.new 'unsubscribe'
        unsubscription[:node] = node
        unsubscription[:jid] = JID.new(jid).stripped
        unsubscription[:subid] = subid
        stanza.pubsub << unsubscription
        stanza
      end
    end

    module InstanceMethods
      def subscription
        if sub = subscription?
          { :node         => sub[:node],
            :jid          => JID.new(sub[:jid]),
            :subid        => sub[:subid],
            :subscription => sub[:subscription] }
        end
      end

      def subscription?
        find_first('pubsub/ns:subscription', :ns => self.class.registered_ns)
      end

      def unsubscribe
        if sub = unsubscribe?
          { :node => sub[:node],
            :jid  => JID.new(sub[:jid]) }
        end
      end

      def unsubscribe?
        find_first('pubsub/ns:unsubscribe', :ns => self.class.registered_ns)
      end
    end

  end #Subscriber

end #PubSub
end #Stanza
end #Blather
