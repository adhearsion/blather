require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::Presence' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:presence, nil).must_equal Stanza::Presence
  end

  it 'ensures type is one of Stanza::Presence::VALID_TYPES' do
    presence = Stanza::Presence.new
    lambda { presence.type = :invalid_type_name }.must_raise(Blather::ArgumentError)
  end

  Stanza::Presence::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Stanza::Presence.new.must_respond_to :"#{valid_type}?"
    end
  end

end
