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
    Blather::XMPPNode.class_from_registration(:c, 'http://jabber.org/protocol/caps' ).must_equal Blather::Stanza::Presence::C
  end

  it 'must be importable' do
    c = Blather::XMPPNode.parse c_xml
    c.must_be_kind_of Blather::Stanza::Presence::C::InstanceMethods
    c.hash.must_equal :'sha-1'
    c.node.must_equal 'http://www.chatopus.com'
    c.ver.must_equal 'zHyEOgxTrkpSdGcQKH8EFPLsriY='
  end

  it 'ensures hash is one of Blather::Stanza::Presence::C::VALID_HASH_TYPES' do
    lambda { Blather::Stanza::Presence::C.new nil, nil, :invalid_type_name }.must_raise(Blather::ArgumentError)

    Blather::Stanza::Presence::C::VALID_HASH_TYPES.each do |valid_hash|
      c = Blather::Stanza::Presence::C.new nil, nil, valid_hash
      c.hash.must_equal valid_hash.to_sym
    end
  end

  it 'can set a hash on creation' do
    c = Blather::Stanza::Presence::C.new nil, nil, :md5
    c.hash.must_equal :md5
  end

  it 'can set a node on creation' do
    c = Blather::Stanza::Presence::C.new 'http://www.chatopus.com'
    c.node.must_equal 'http://www.chatopus.com'
  end

  it 'can set a ver on creation' do
    c = Blather::Stanza::Presence::C.new nil, 'zHyEOgxTrkpSdGcQKH8EFPLsriY='
    c.ver.must_equal 'zHyEOgxTrkpSdGcQKH8EFPLsriY='
  end

  it 'is equal on import and creation' do
    p = Blather::XMPPNode.parse c_xml
    c = Blather::Stanza::Presence::C.new 'http://www.chatopus.com', 'zHyEOgxTrkpSdGcQKH8EFPLsriY=', 'sha-1'
    p.must_equal c
  end
end
