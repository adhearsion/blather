module Blather
module DSL

  class PubSub
    attr_accessor :host

    def initialize(host)
      @host = host
    end

    ##
    # Retrieve Affiliations
    # Yields a hash of affiliations in the form:
    #   {:aff_type => ['node1', 'node2']}
    def affiliations(host = nil, &callback)
      request Stanza::PubSub::Affiliations.new(:get, send_to(host)), :list, callback
    end

    ##
    # Retrieve Subscriptions
    # Yields a hash of subscriptions in the form:
    #   {:sub_type => [{:node => 'node1', :jid => 'j@d'}]}
    def subscriptions(host = nil, &callback)
      request Stanza::PubSub::Subscriptions.new(:get, send_to(host)), :list, callback
    end

    ##
    # Discover Nodes
    # Yields a list of DiscoItem::Item objects
    #   +path+ is the node's path. Default is '/'
    def nodes(path = nil, host = nil, &callback)
      path ||= '/'
      stanza = Stanza::DiscoItems.new(:get, path)
      stanza.to = send_to(host)
      request stanza, :items, callback
    end

    ##
    # Discover node information
    # Yields a DiscoInfo node
    #   +path+ is the node's path
    def node(path, host = nil, &callback)
      stanza = Stanza::DiscoInfo.new(:get, path)
      stanza.to = send_to(host)
      request stanza, nil, callback
    end

    ##
    # Retrieve items for a node
    #   +path+ is the node's path
    #   +list+ can be an array of items to retrieve
    #   +max+ can be the maximum number of items to return
    def items(path, list = [], max = nil, host = nil, &callback)
      request Stanza::PubSub::Items.request(send_to(host), path, list, max), :items, callback
    end

    ##
    # Subscribe to a node
    # Yields the resulting Subscription object
    #   +node+ is the node to subscribe to
    #   +jid+ is the jid that should be used. Defaults to the stripped current JID
    def subscribe(node, jid = nil, host = nil)
      jid ||= DSL.client.jid.stripped
      request(Stanza::PubSub::Subscribe.new(:set, send_to(host), node, jid)) { |n| yield n if block_given? }
    end

    ##
    # Unsubscribe from a node
    # Yields the resulting Unsubscribe object
    #   +node+ is the node to subscribe to
    #   +jid+ is the jid that should be used. Defaults to the stripped current JID
    def unsubscribe(node, jid = nil, host = nil)
      jid ||= DSL.client.jid.stripped
      request(Stanza::PubSub::Unsubscribe.new(:set, send_to(host), node, jid)) { |n| yield n if block_given? }
    end

    ##
    # Publish an item to a node
    # Yields the resulting Publish node
    #   +node+ is the node to publish to
    #   +payload+ is the payload to send (see Blather::Stanza::PubSub::Publish for details)
    def publish(node, payload, host = nil)
      request(Stanza::PubSub::Publish.new(send_to(host), node, :set, payload)) { |n| yield n if block_given? }
    end

    ##
    # Delete items from a node
    # Yields the resulting node
    #   +node+ is the node to retract items from
    #   +ids+ is a list of ids to retract. This can also be a single id
    def retract(node, ids = [], host = nil)
      request(Stanza::PubSub::Retract.new(send_to(host), node, :set, ids)) { |n| yield n if block_given? }
    end

    ##
    # Create a node
    # Yields the resulting node
    # This does not (yet) handle configuration
    #   +node+ is the node to create
    def create(node, host = nil)
      request(Stanza::PubSub::Create.new(:set, send_to(host), node)) { |n| yield n if block_given? }
    end

    ##
    # Purge all node items
    # Yields the resulting node
    #   +node+ is the node to purge
    def purge(node, host = nil)
      request(Stanza::PubSubOwner::Purge.new(:set, send_to(host), node)) { |n| yield n if block_given? }
    end

    ##
    # Delete a node
    # Yields the resulting node
    #   +node+ is the node to delete
    def delete(node, host = nil)
      request(Stanza::PubSubOwner::Delete.new(:set, send_to(host), node)) { |n| yield n if block_given? }
    end

  private
    def request(node, method = nil, callback = nil, &block)
      block = lambda { |node| callback.call(method ? node.__send__(method) : node) } unless block_given?
      DSL.client.write_with_handler(node, &block)
    end

    def send_to(host = nil)
      raise 'You must provide a host' unless (host ||= @host)
      host
    end
  end

end
end
