module Blather

  ##
  # Local Roster 
  # Takes care of adding/removing JIDs through the stream
  class Roster
    include Enumerable

    def initialize(stream, stanza = nil)
      @stream = stream
      @items = {}
      stanza.items.each { |i| push i, false } if stanza
    end

    ##
    # Process any incoming stanzas adn either add or remove the
    # corresponding RosterItem
    def process(stanza)
      stanza.items.each do |i|
        case i.subscription
        when :remove then @items.delete(key(i.jid))
        else @items[key(i.jid)] = RosterItem.new(i)
        end
      end
    end

    ##
    # Pushes a JID into the roster
    # then returns self to allow for chaining
    def <<(elem)
      push elem
      self
    end

    ##
    # Push a JID into the roster
    # Will send the new item to the server
    # unless overridden by calling #push(elem, false)
    def push(elem, send = true)
      jid = elem.respond_to?(:jid) ? elem.jid : JID.new(elem)
      @items[key(jid)] = node = RosterItem.new(elem)

      @stream.write(node.to_stanza(:set)) if send
    end
    alias_method :add, :push

    ##
    # Remove a JID from the roster
    # Sends a remove query stanza to the server
    def delete(jid)
      @items.delete key(jid)
      @stream.write Stanza::Iq::Roster.new(:set, Stanza::Iq::Roster::RosterItem.new(jid, nil, :remove))
    end
    alias_method :remove, :delete

    ##
    # Get a RosterItem by JID
    def [](jid)
      items[key(jid)]
    end

    ##
    # Iterate over all RosterItems
    def each(&block)
      items.each &block
    end

    ##
    # Returns a duplicate of all RosterItems
    def items
      @items.dup
    end

    ##
    # A hash of items keyed by group
    def grouped
      self.inject(Hash.new{|h,k|h[k]=[]}) do |hash, item|
        item[1].groups.each { |group| hash[group] << item[1] }
        hash
      end
    end

  private
    def self.key(jid)
      JID.new(jid).stripped.to_s
    end

    def key(jid)
      self.class.key(jid)
    end
  end #Roster

end