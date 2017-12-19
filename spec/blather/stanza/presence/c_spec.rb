require 'spec_helper'

def c_xml
  <<-XML
    <presence from='bard@shakespeare.lit/globe'>
      <c xmlns='http://jabber.org/protocol/caps'
         hash='sha-1'
         node='http://www.chatopus.com'
         ver='zHyEOgxTrkpSdGcQKH8EFPLsriY='/>
    </presence>
  XML
end

describe 'Blather::Stanza::Presence::C' do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:c, 'http://jabber.org/protocol/caps' )).to eq(Blather::Stanza::Presence::C)
  end

  it 'must be importable' do
    c = Blather::XMPPNode.parse c_xml
    expect(c).to be_kind_of Blather::Stanza::Presence::C::InstanceMethods
    expect(c.hash).to eq(:'sha-1')
    expect(c.node).to eq('http://www.chatopus.com')
    expect(c.ver).to eq('zHyEOgxTrkpSdGcQKH8EFPLsriY=')
  end

  it 'ensures hash is one of Blather::Stanza::Presence::C::VALID_HASH_TYPES' do
    expect { Blather::Stanza::Presence::C.new nil, nil, :invalid_type_name }.to raise_error(Blather::ArgumentError)

    Blather::Stanza::Presence::C::VALID_HASH_TYPES.each do |valid_hash|
      c = Blather::Stanza::Presence::C.new nil, nil, valid_hash
      expect(c.hash).to eq(valid_hash.to_sym)
    end
  end

  it 'can set a hash on creation' do
    c = Blather::Stanza::Presence::C.new nil, nil, :md5
    expect(c.hash).to eq(:md5)
  end

  it 'can set a node on creation' do
    c = Blather::Stanza::Presence::C.new 'http://www.chatopus.com'
    expect(c.node).to eq('http://www.chatopus.com')
  end

  it 'can set a ver on creation' do
    c = Blather::Stanza::Presence::C.new nil, 'zHyEOgxTrkpSdGcQKH8EFPLsriY='
    expect(c.ver).to eq('zHyEOgxTrkpSdGcQKH8EFPLsriY=')
  end

  it 'is equal on import and creation' do
    p = Blather::XMPPNode.parse c_xml
    c = Blather::Stanza::Presence::C.new 'http://www.chatopus.com', 'zHyEOgxTrkpSdGcQKH8EFPLsriY=', 'sha-1'
    expect(p).to eq(c)
  end
end
