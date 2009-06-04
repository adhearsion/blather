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
      request Stanza::PubSub.items(send_to(host), path, list, max), :items, callback
    end

    def publish(node, payload, host = nil)
      request(Stanza::PubSub::Publish.new(send_to(host), node, :set, payload)) { |n| yield n if block_given? }
    end

    def retract(node, ids = [], host = nil)
      request(Stanza::PubSub::Retract.new(send_to(host), node, :set, ids)) { |n| yield n if block_given? }
    end

    def subscribe(node, jid = nil)
      jid ||= DSL.client.jid.stripped
      request(Stanza::PubSub::Subscribe.new(:set, send_to(host), node, jid)) { |n| yield n if block_given? }
    end
=begin
    def create(node)
    end

    def subscribe(node)
      DSL.client.write Stanza::PubSub::Subscribe.new(:set, host, node, DSL.client.jid)
    end

    def unsubscribe(node)
      DSL.client.write Stanza::PubSub::Unsubscribe.new(:set, host, node, DSL.client.jid)
    end
=end
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