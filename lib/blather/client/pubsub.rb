module Blather
class Client

  class PubSub
    attr_accessor :host

    def nodes(path, &block)
      DSL.client.write_with_handler Stanza::DiscoItems.new(:get, node), &block
    end

    def node(path, &block)
      if block_given?
        Node.new(path).info &block
      else
        Node.new(path)
      end
    end

    def affiliations(&callback)
      DSL.client.write_with_handler Stanza::PubSub.affiliations, &callback
    end

    def subscriptions(&callback)
      DSL.client.write_with_handler Stanza::PubSub.subscriptions, &callback
    end

    def create(node)
      
    end

    def publish(node, payload)
    end

    def subscribe(node)
      DSL.client.write Stanza::PubSub::Subscribe.new(:set, host, node, DSL.client.jid)
    end

    def unsubscribe(node)
      DSL.client.write Stanza::PubSub::Unsubscribe.new(:set, host, node, DSL.client.jid)
    end
  end

end
end