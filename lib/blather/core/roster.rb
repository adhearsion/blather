module Blather

  class Roster
    include Enumerable

    def initialize(stream, stanza = nil)
      @stream = stream
      @items = {}
      stanza.items.each { |i| push i, false } if stanza
    end

    def process(stanza)
      stanza.items.each do |i|
        case i.subscription
        when :remove then @items.delete(key(i.jid))
        else @items[key(i.jid)] = RosterItem.new(i)
        end
      end
    end

    def <<(elem)
      push elem
      self
    end

    def push(elem, send = true)
      jid = elem.respond_to?(:jid) ? elem.jid : JID.new(elem)
      @items[key(jid)] = node = RosterItem.new(elem)

      @stream.send_data(node.to_stanza(:set)) if send
    end
    alias_method :add, :push

    def delete(jid)
      @items.delete key(jid)
      @stream.send_data Stanza::Iq::Roster.new(:set, Stanza::Iq::Roster::RosterItem.new(jid, nil, :remove))
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