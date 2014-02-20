module Blather

  # Local Roster
  # Takes care of adding/removing JIDs through the stream
  class Roster
    include Enumerable

    # Create a new roster
    #
    # @param [Blather::Stream] stream the stream the roster should use to
    # update roster entries
    # @param [Blather::Stanza::Roster] stanza a roster stanza used to preload
    # the roster
    # @return [Blather::Roster]
    def initialize(stream, stanza = nil)
      @stream = stream
      @items = {}
      stanza.items.each { |i| push i, false } if stanza
    end

    # Process any incoming stanzas and either adds or removes the
    # corresponding RosterItem
    #
    # @param [Blather::Stanza::Roster] stanza a roster stanza
    def process(stanza)
      stanza.items.each do |i|
        case i.subscription
        when :remove then @items.delete(key(i.jid))
        else @items[key(i.jid)] = RosterItem.new(i)
        end
      end
    end

    # Pushes a JID into the roster
    #
    # @param [String, Blather::JID, #jid] elem a JID to add to the roster
    # @return [self]
    # @see #push
    def <<(elem)
      push elem
      self
    end

    # Push a JID into the roster and update the server
    #
    # @param [String, Blather::JID, #jid] elem a jid to add to the roster
    # @param [true, false] send send the update over the wire
    # @see Blather::JID
    def push(elem, send = true)
      jid = elem.respond_to?(:jid) && elem.jid ? elem.jid : JID.new(elem)
      @items[key(jid)] = node = RosterItem.new(elem)

      @stream.write(node.to_stanza(:set)) if send
    end
    alias_method :add, :push

    # Remove a JID from the roster and update the server
    #
    # @param [String, Blather::JID] jid the JID to remove from the roster
    def delete(jid)
      @items.delete key(jid)
      item = Stanza::Iq::Roster::RosterItem.new(jid, nil, :remove)
      @stream.write Stanza::Iq::Roster.new(:set, item)
    end
    alias_method :remove, :delete

    # Get a RosterItem by JID
    #
    # @param [String, Blather::JID] jid the jid of the item to return
    # @return [Blather::RosterItem, nil] the associated RosterItem
    def [](jid)
      items[key(jid)]
    end

    # Iterate over all RosterItems
    #
    # @yield [Blather::RosterItem] yields each RosterItem
    def each(&block)
      items.values.each &block
    end

    # Get a duplicate of all RosterItems
    #
    # @return [Array<Blather::RosterItem>] a duplicate of all RosterItems
    def items
      @items.dup
    end

    # Number of items in the roster
    #
    # @return [Integer] the number of items in the roster
    def length
      @items.length
    end

    # A hash of items keyed by group
    #
    # @return [Hash<group => Array<RosterItem>>]
    def grouped
      @items.values.sort.inject(Hash.new{|h,k|h[k]=[]}) do |hash, item|
        item.groups.each { |group| hash[group] << item }
        hash
      end
    end

  private
    # Creates a stripped jid
    def self.key(jid)
      JID.new(jid).stripped.to_s.downcase
    end

    # Instance method to wrap around the class method
    def key(jid)
      self.class.key(jid)
    end
  end  # Roster

end  # Blather
