require 'spec_helper'

describe Blather::Stanza::Presence do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:presence, nil).must_equal Blather::Stanza::Presence
  end

  it 'must be importable' do
    Blather::XMPPNode.parse('<presence type="probe"/>').must_be_instance_of Blather::Stanza::Presence
  end

  it 'ensures type is one of Blather::Stanza::Presence::VALID_TYPES' do
    presence = Blather::Stanza::Presence.new
    lambda { presence.type = :invalid_type_name }.must_raise(Blather::ArgumentError)

    Blather::Stanza::Presence::VALID_TYPES.each do |valid_type|
      presence.type = valid_type
      presence.type.must_equal valid_type
    end
  end

  Blather::Stanza::Presence::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Blather::Stanza::Presence.new.must_respond_to :"#{valid_type}?"
    end

    it "returns true on call to (#{valid_type}?) if type == #{valid_type}" do
      method = "#{valid_type}?".to_sym
      pres = Blather::Stanza::Presence.new
      pres.type = valid_type
      pres.must_respond_to method
      pres.__send__(method).must_equal true
    end
  end

  it 'creates a Status object when importing a node with type == nil' do
    s = Blather::Stanza::Presence.parse('<presence/>')
    s.must_be_kind_of Blather::Stanza::Presence::Status
    s.state.must_equal :available
  end

  it 'creates a Status object when importing a node with type == "unavailable"' do
    s = Blather::Stanza::Presence.parse('<presence type="unavailable"/>')
    s.must_be_kind_of Blather::Stanza::Presence::Status
    s.state.must_equal :unavailable
  end

  it 'creates a Subscription object when importing a node with type == "subscribe"' do
    s = Blather::Stanza::Presence.parse('<presence type="subscribe"/>')
    s.must_be_kind_of Blather::Stanza::Presence::Subscription
    s.type.must_equal :subscribe
  end

  it 'creates a MUC object when importing a node with a form in the MUC namespace' do
    n = Blather::XMPPNode.new
    x = Blather::XMPPNode.new 'x'
    x.namespace = "http://jabber.org/protocol/muc"
    n << x
    s = Blather::Stanza::Presence.import(n)
    s.must_be_kind_of Blather::Stanza::Presence::MUC
  end

  it 'creates a MUCUser object when importing a node with a form in the MUC#user namespace' do
    n = Blather::XMPPNode.new
    x = Blather::XMPPNode.new 'x'
    x.namespace = "http://jabber.org/protocol/muc#user"
    n << x
    s = Blather::Stanza::Presence.import(n)
    s.must_be_kind_of Blather::Stanza::Presence::MUCUser
  end

  it 'creates a Presence object when importing a node with type equal to something unknown' do
    n = Blather::XMPPNode.new
    n[:type] = :foo
    s = Blather::Stanza::Presence.import(n)
    s.must_be_kind_of Blather::Stanza::Presence
    s.type.must_equal :foo
  end
end
