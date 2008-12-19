require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::Iq' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:iq, nil).must_equal Stanza::Iq
  end

  
end
