module Blather
module DSL

  class PubSub
    attr_accessor :host

    def initialize(host)
      @host = host
    end

    def affiliations(host = nil, &callback)
      request Stanza::PubSub::Affiliations.new(:get, send_to(host)), :affiliates, callback
    end

    def subscriptions(host = nil, &callback)
      request Stanza::PubSub::Subscriptions.new(:get, send_to(host)), :subscriptions, callback
    end

    def nodes(path = nil, host = nil, &callback)
      path ||= '/'
      stanza = Stanza::DiscoItems.new(:get, path)
      stanza.to = send_to(host)
      request stanza, :items, callback
    end

    def node(path, host = nil)
      stanza = Stanza::DiscoInfo.new(:get, path)
      stanza.to = send_to(host)
      request(stanza) { |node| yield Stanza::PubSub::Node.import(node) }
    end

    def items(path, list = [], max = nil, host = nil, &callback)
      request Stanza::PubSub::Items.request(send_to(host), path, list, max), :items, callback
    end

    def publish(node, payload, host = nil)
      request(Stanza::PubSub::Publish.new(send_to(host), node, :set, payload)) { |n| yield n if block_given? }
    end

    def retract(node, ids = [], host = nil)
      request(Stanza::PubSub::Retract.new(send_to(host), node, :set, ids)) { |n| yield n if block_given? }
    end

    def subscribe(node, jid = nil, host = nil)
      jid ||= DSL.client.jid.stripped
      request(Stanza::PubSub::Subscribe.new(:set, send_to(host), node, jid)) { |n| yield n if block_given? }
    end

    def unsubscribe(node, jid = nil, host = nil)
      jid ||= DSL.client.jid.stripped
      request(Stanza::PubSub::Unsubscribe.new(:set, send_to(host), node, jid)) { |n| yield n if block_given? }
    end

    def purge(node, host = nil)
      request(Stanza::PubSubOwner::Purge.new(:set, send_to(host), node)) { |n| yield n if block_given? }
    end

    def create(node, host = nil)
      request(Stanza::PubSubOwner::Create.new(:set, send_to(host), node)) { |n| yield n if block_given? }
    end

    def delete(node, host = nil)
      request(Stanza::PubSubOwner::Delete.new(:set, send_to(host), node)) { |n| yield n if block_given? }
    end

  private
    def request(node, method = nil, callback = nil, &block)
      block = lambda { |node| callback.call node.__send__(method) } unless block_given?
      DSL.client.write_with_handler(node, &block)
    end

    def send_to(host = nil)
      raise 'You must provide a host' unless (host ||= @host)
      host
    end
  end

end
end
