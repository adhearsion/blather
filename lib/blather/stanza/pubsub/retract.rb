module Blather
class Stanza
class PubSub

  # # PubSub Retract Stanza
  #
  # [XEP-0060 Section 7.2 - Delete an Item from a Node](http://xmpp.org/extensions/xep-0060.html#publisher-delete)
  #
  # @handler :pubsub_retract
  class Retract < PubSub
    register :pubsub_retract, :retract, self.registered_ns

    include Enumerable
    alias_method :find, :xpath

    # Createa new Retraction stanza
    #
    # @param [String] host the host to send the request to
    # @param [String] node the node to retract items from
    # @param [Blather::Stanza::Iq::VALID_TYPES] type the IQ stanza type
    # @param [Array<String>] retractions an array of ids to retract
    def self.new(host = nil, node = nil, type = :set, retractions = [])
      new_node = super(type, host)
      new_node.node = node
      new_node.retractions = retractions
      new_node
    end

    # Get the name of the node to retract from
    #
    # @return [String]
    def node
      retract[:node]
    end

    # Set the name of the node to retract from
    #
    # @param [String] node
    def node=(node)
      retract[:node] = node
    end

    # Get or create the actual retract node
    #
    # @return [Blather::XMPPNode]
    def retract
      unless retract = pubsub.find_first('ns:retract', :ns => self.class.registered_ns)
        self.pubsub << (retract = XMPPNode.new('retract', self.document))
        retract.namespace = self.pubsub.namespace
      end
      retract
    end

    # Set the retraction ids
    #
    # @overload retractions=(id)
    #   @param [String] id an ID to retract
    # @overload retractions=(ids)
    #   @param [Array<String>] ids an array of IDs to retract
    def retractions=(retractions = [])
      [retractions].flatten.each do |id|
        self.retract << PubSubItem.new(id, nil, self.document)
      end
    end

    # Get the list of item IDs to retract
    #
    # @return [Array<String>]
    def retractions
      retract.find('ns:item', :ns => self.class.registered_ns).map do |i|
        i[:id]
      end
    end

    # Iterate over each retraction ID
    #
    # @yieldparam [String] id an ID to retract
    def each(&block)
      retractions.each &block
    end

    # The size of the retractions array
    #
    # @return [Fixnum]
    def size
      retractions.size
    end
  end  # Retract

end  # PubSub
end  # Stanza
end  # Blather
