require 'spec_helper'

def muc_xml
  <<-XML
    <presence from='hag66@shakespeare.lit/pda'
              id='n13mt3l'
              to='coven@chat.shakespeare.lit/thirdwitch'>
      <x xmlns='http://jabber.org/protocol/muc'/>
    </presence>
  XML
end

describe 'Blather::Stanza::Presence::MUC' do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:x, 'http://jabber.org/protocol/muc' ).must_equal Blather::Stanza::Presence::MUC
  end

  it 'must be importable' do
    c = Blather::XMPPNode.import(parse_stanza(muc_xml).root).must_be_instance_of Blather::Stanza::Presence::MUC
  end
end
