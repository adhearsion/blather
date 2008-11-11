module Blather

  class Roster
    include Enumerable

    def initialize(stream, stanza = nil)
      @stream = stream
      @items = {}
      stanza.items.each { |i| push i } if stanza
    end

    def process(stanza)
      return unless stanza.is_a?(Iq::Roster)

      stanza.items.each do |i|
        case i.subscription
        when :remove then @items.delete(key(i.jid))
        else @items[key(i.jid)] = RosterItem.new(@stream, i)
        end
      end
    end

    def <<(elem)
      push elem
      self
    end

    def push(elem)
      jid = elem.respond_to?(:jid) ? elem.jid : JID.new(elem)
      @items[key(jid)] = node = RosterItem.new(@stream, elem)

      @stream.send_data node.to_stanza(:set)
    end
    alias_method :add, :push

    def delete(jid)
      @items.delete key(jid)
      @stream.send_data Iq::Roster.new(:set, Iq::RosterItem.new(jid, nil, :remove))
    end
    alias_method :remove, :delete

    def [](jid)
      items[key(jid)]
    end

    def each(&block)
      items.each &block
    end

    def items
      @items.dup
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