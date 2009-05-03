module Blather
class Client

  class PubSub
    attr_accessor :host

    def affiliations(&callback)
      request Stanza::PubSub.affiliations(@host), :affiliates, callback
    end

    def subscriptions(&callback)
      request Stanza::PubSub.subscriptions(@host), :subscriptions, callback
    end

    def nodes(path, &callback)
      stanza = Stanza::DiscoItems.new(:get, path)
      stanza.to = @host
      request stanza, :items, callback
    end

    def node(path)
      stanza = Stanza::DiscoInfo.new(:get, path)
      stanza.to = @host
      request(stanza) { |node| yield Stanza::PubSub::Node.import(node) }
    end

    def items(path, list = [], max = nil, &callback)
      request Stanza::PubSub.items(@host, path, list, max), :items, callback
    end
=begin
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
=end
  private
    def request(node, method = nil, callback, &block)
      block = lambda { |node| callback.call node.__send__(method) } unless block_given?
      DSL.client.write_with_handler(node, &block)
    end
  end

end
end