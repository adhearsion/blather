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
    expect(Blather::XMPPNode.class_from_registration(:x, 'http://jabber.org/protocol/muc' )).to eq(Blather::Stanza::Presence::MUC)
  end

  it 'must be importable' do
    c = Blather::XMPPNode.parse(muc_xml)
    expect(c).to be_kind_of Blather::Stanza::Presence::MUC::InstanceMethods
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUC.registered_ns).count).to eq(1)
  end

  it 'ensures a form node is present on create' do
    c = Blather::Stanza::Presence::MUC.new
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUC.registered_ns)).not_to be_empty
  end

  it 'ensures a form node exists when calling #muc' do
    c = Blather::Stanza::Presence::MUC.new
    c.remove_children :x
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUC.registered_ns)).to be_empty

    expect(c.muc).not_to be_nil
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUC.registered_ns)).not_to be_empty
  end
end
