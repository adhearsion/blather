require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::Iq' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:iq, nil).must_equal Stanza::Iq
  end

  it 'creates a new Iq stanza defaulted as a get' do
    Stanza::Iq.new.type.must_equal :get
  end
end
