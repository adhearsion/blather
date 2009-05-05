module Blather
class Stanza

  class PubSub < Iq
    register :pubsub, :pubsub, 'http://jabber.org/protocol/pubsub'

    ##
    # Ensure the namespace is set to the query node
    def initialize(type = nil, host = nil)
      super type
      self.to = host
      pubsub.namespace = self.class.ns unless pubsub.namespace
    end

    ##
    # Kill the pubsub node before running inherit
    def inherit(node)
      pubsub.remove!
      super
    end

    def pubsub
      unless p = find_first('//pubsub', Stanza::PubSub::Affiliations.ns)
        p = XMPPNode.new('pubsub')
        p.namespace = self.class.ns
        self << p
      end
      p
    end
  end

end #Stanza
end #Blather
