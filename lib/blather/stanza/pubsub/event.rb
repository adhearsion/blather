module Blather
class Stanza
class PubSub

  class Event < Message
    register :pubsub_event, nil, 'http://jabber.org/protocol/pubsub#event'

    def items
    end

    class Item
      attribute_accessor :id, :node, :to_sym => false

      alias_method :payload, :content
      alias_method :payload=, :content=
    end
  end

end #PubSub
end #Stanza
end #Blather
