module Blather
class Stanza
module MUC

#  <x xmlns='http://jabber.org/protocol/muc#user'>
#    <status code="100"/>
#  </x>
class Status < Stanza
  register :muc_status, :status, "http://jabber.org/protocol/muc#user"

  def self.import(node)
    self.new.inherit(node)
  end

  def inherit(node)
    create_status.remove
    self << node.find_first('ns:x/ns:status', :ns => self.class.registered_ns)
    self
  end

  def self.new(code = nil)
    status = super :x
    status.code = code
    status
  end

  def code
    create_status[:code]
  end

  def code=(code)
    return unless code
    raise ArgumentError unless code.is_a?(Fixnum) && code >= 100 && code <= 999
    create_status[:code] = code
  end

  protected

  def create_status
    unless create_status = find_first('ns:status', :ns => self.class.registered_ns)
      self << (create_status = XMPPNode.new('status', self.document))
    end
    create_status
  end
end

end
end
end
