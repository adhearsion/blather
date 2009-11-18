module Blather
module DSL

  class PubSub
    attr_accessor :host

    # Create a new pubsub DSL
    #
    # @param [Blather::Client] client the client who's connection will be used
    # @param [#to_s] host the PubSub host
    def initialize(client, host)
      @client = client
      @host = host
    end

    # Retrieve Affiliations
    #
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Hash] affiliations See {Blather::Stanza::PubSub::Affiliations#list}
    def affiliations(host = nil, &callback)
      request Stanza::PubSub::Affiliations.new(:get, send_to(host)), :list, callback
    end

    # Retrieve Subscriptions
    #
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Hash] affiliations See {Blather::Stanza::PubSub::Subscriptions#list}
    def subscriptions(host = nil, &callback)
      request Stanza::PubSub::Subscriptions.new(:get, send_to(host)), :list, callback
    end

    # Discover Nodes
    #
    # @param [#to_s] path the node path
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Array<Blather::Stanza::DiscoItems::Item>] items
    def nodes(path = nil, host = nil, &callback)
      path ||= '/'
      stanza = Stanza::DiscoItems.new(:get, path)
      stanza.to = send_to(host)
      request stanza, :items, callback
    end

    # Discover node information
    #
    # @param [#to_s] path the node path
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza::DiscoInfo>] info
    def node(path, host = nil, &callback)
      stanza = Stanza::DiscoInfo.new(:get, path)
      stanza.to = send_to(host)
      request stanza, nil, callback
    end

    # Retrieve items for a node
    #
    # @param [#to_s] path the node path
    # @param [Array<#to_s>] list a list of IDs to retrieve
    # @param [Fixnum, #to_s] max the maximum number of items to return
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Array<Blather::Stanza::PubSub::PubSubItem>] items see {Blather::Stanza::PubSub::Items#items}
    def items(path, list = [], max = nil, host = nil, &callback)
      request(
        Stanza::PubSub::Items.request(send_to(host), path, list, max),
        :items,
        callback
      )
    end

    # Subscribe to a node
    #
    # @param [#to_s] node the node to subscribe to
    # @param [Blather::JID, #to_s] jid is the jid that should be used.
    # Defaults to the stripped current JID
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza] stanza the reply stanza
    def subscribe(node, jid = nil, host = nil)
      jid ||= client.jid.stripped
      stanza = Stanza::PubSub::Subscribe.new(:set, send_to(host), node, jid)
      request(stanza) { |n| yield n if block_given? }
    end

    # Unsubscribe from a node
    #
    # @param [#to_s] node the node to unsubscribe from
    # @param [Blather::JID, #to_s] jid is the jid that should be used.
    # Defaults to the stripped current JID
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza] stanza the reply stanza
    def unsubscribe(node, jid = nil, host = nil)
      jid ||= client.jid.stripped
      stanza = Stanza::PubSub::Unsubscribe.new(:set, send_to(host), node, jid)
      request(stanza) { |n| yield n if block_given? }
    end

    # Publish an item to a node
    #
    # @param [#to_s] node the node to publish to
    # @param [#to_s] payload the payload to send see {Blather::Stanza::PubSub::Publish}
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza] stanza the reply stanza
    def publish(node, payload, host = nil)
      stanza = Stanza::PubSub::Publish.new(send_to(host), node, :set, payload)
      request(stanza) { |n| yield n if block_given? }
    end

    # Delete items from a node
    #
    # @param [#to_s] node the node to delete from
    # @param [Array<#to_s>] ids a list of ids to delete
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza] stanza the reply stanza
    def retract(node, ids = [], host = nil)
      stanza = Stanza::PubSub::Retract.new(send_to(host), node, :set, ids)
      request(stanza) { |n| yield n if block_given? }
    end

    # Create a node
    #
    # @param [#to_s] node the node to create
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza] stanza the reply stanza
    def create(node, host = nil)
      stanza = Stanza::PubSub::Create.new(:set, send_to(host), node)
      request(stanza) { |n| yield n if block_given? }
    end

    # Purge all node items
    #
    # @param [#to_s] node the node to purge
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza] stanza the reply stanza
    def purge(node, host = nil)
      stanza = Stanza::PubSubOwner::Purge.new(:set, send_to(host), node)
      request(stanza) { |n| yield n if block_given? }
    end

    # Delete a node
    #
    # @param [#to_s] node the node to delete
    # @param [#to_s] host the PubSub host (defaults to the initialized host)
    # @yield [Blather::Stanza] stanza the reply stanza
    def delete(node, host = nil)
      stanza = Stanza::PubSubOwner::Delete.new(:set, send_to(host), node)
      request(stanza) { |n| yield n if block_given? }
    end

  private
    def request(node, method = nil, callback = nil, &block)
      unless block_given?
        block = lambda do |node|
          callback.call(method ? node.__send__(method) : node)
        end
      end

      client.write_with_handler(node, &block)
    end

    def send_to(host = nil)
      raise 'You must provide a host' unless (host ||= @host)
      host
    end

    def client
      @client
    end
  end  # PubSub

end  # DSL
end  # Blather
