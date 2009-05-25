require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

module Blather
  describe 'Blather::Stanza::Presence' do
    it 'registers itself' do
      XMPPNode.class_from_registration(:presence, nil).must_equal Stanza::Presence
    end

    it 'ensures type is one of Stanza::Presence::VALID_TYPES' do
      presence = Stanza::Presence.new
      lambda { presence.type = :invalid_type_name }.must_raise(Blather::ArgumentError)

      Stanza::Presence::VALID_TYPES.each do |valid_type|
        presence.type = valid_type
        presence.type.must_equal valid_type
      end
    end

    Stanza::Presence::VALID_TYPES.each do |valid_type|
      it "provides a helper (#{valid_type}?) for type #{valid_type}" do
        Stanza::Presence.new.must_respond_to :"#{valid_type}?"
      end
    end

    it 'creates a Status object when importing a node with type == nil' do
      s = Stanza::Presence.import(XMPPNode.new)
      s.must_be_kind_of Stanza::Presence::Status
      s.state.must_equal :available
    end

    it 'creates a Status object when importing a node with type == "unavailable"' do
      n = XMPPNode.new
      n[:type] = :unavailable
      s = Stanza::Presence.import(n)
      s.must_be_kind_of Stanza::Presence::Status
      s.state.must_equal :unavailable
    end

    it 'creates a Subscription object when importing a node with type == "subscribe"' do
      n = XMPPNode.new
      n[:type] = :subscribe
      s = Stanza::Presence.import(n)
      s.must_be_kind_of Stanza::Presence::Subscription
      s.type.must_equal :subscribe
    end

    it 'creates a Presence object when importing a node with type equal to something unkown' do
      n = XMPPNode.new
      n[:type] = :foo
      s = Stanza::Presence.import(n)
      s.must_be_kind_of Stanza::Presence
      s.type.must_equal :foo
    end
  end
end
