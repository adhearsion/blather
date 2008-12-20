require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

describe 'Blather::Stanza::Iq::Roster' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:query, 'jabber:iq:roster').must_equal Stanza::Iq::Roster
  end
end