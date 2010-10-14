require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

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
    c = Blather::XMPPNode.import(parse_stanza(c_xml).root).must_be_instance_of Blather::Stanza::Presence::C
  end

  it 'ensures hash is one of Blather::Stanza::Presence::C::VALID_HASH_TYPES' do
    lambda { Blather::Stanza::Presence::C.new nil, nil, :invalid_type_name }.must_raise(Blather::ArgumentError)

    Blather::Stanza::Presence::C::VALID_HASH_TYPES.each do |valid_hash|
      c = Blather::Stanza::Presence::C.new nil, nil, valid_hash
      c.hash.must_equal valid_hash
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
end