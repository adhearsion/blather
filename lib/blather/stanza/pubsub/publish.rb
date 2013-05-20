module Blather
class Stanza
class PubSub

  # # PubSub Publish Stanza
  #
  # [XEP-0060 Section 7.1 - Publish an Item to a Node](http://xmpp.org/extensions/xep-0060.html#publisher-publish)
  #
  # @handler :pubsub_publish
  class Publish < PubSub
    register :pubsub_publish, :publish, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    # Create a new publish node
    #
    # @param [String, nil] host the host to pushlish the node to
    # @param [String, nil] node the name of the node to publish to
    # @param [Blather::Stanza::Iq::VALID_TYPES] type the node type
    # @param [#to_s] payload the payload to publish see {#payload=}
    def self.new(host = nil, node = nil, type = :set, payload = nil)
      new_node = super(type, host)
      new_node.publish
      new_node.node = node if node
      new_node.payload = payload if payload
      new_node
    end

    # Set the payload to publish
    #
    # @overload payload=(hash)
    #   Set the payload as a set of ID => payload entries
    #   @param [Hash<id => payload>] hash
    # @overload payload=(array)
    #   Set the list of payloads all at once
    #   @param [Array<#to_s>] array
    # @overload payload=(string)
    #   Set the payload as a string
    #   @param [#to_s] string
    def payload=(payload)
      payload = case payload
      when Hash   then  payload.to_a
      when Array  then  payload.map { |v| [nil, v] }
      else              [[nil, payload]]
      end
      payload.each do |id, value|
        self.publish << PubSubItem.new(id, value, self.document)
      end
    end

    # Get the name of the node to publish to
    #
    # @return [String, nil]
    def node
      publish[:node]
    end

    # Set the name of the node to publish to
    #
    # @param [String, nil] node
    def node=(node)
      publish[:node] = node
    end

    # Get or create the actual publish node
    #
    # @return [Blather::XMPPNode]
    def publish
      unless publish = pubsub.at_xpath('ns:publish', :ns => self.class.registered_ns)
        self.pubsub << (publish = XMPPNode.new('publish', self.document))
        publish.namespace = self.pubsub.namespace
      end
      publish
    end

    # Get the list of items
    #
    # @return [Array<Blather::Stanza::PubSub::PubSubItem>]
    def items
      publish.xpath('ns:item', :ns => self.class.registered_ns).map do |i|
        PubSubItem.new(nil,nil,self.document).inherit i
      end
    end

    # Iterate over the list of items
    #
    # @yield [item] a block to accept each item
    # @yieldparam [Blather::Stanza::PubSub::PubSubItem]
    def each(&block)
      items.each &block
    end

    # Get the size of the items list
    #
    # @return [Fixnum]
    def size
      items.size
    end
  end  # Publish

end  # PubSub
end  # Stanza
end  # Blather
