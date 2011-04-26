require 'spec_helper'

describe Blather::Stanza::Iq do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:iq, nil).must_equal Blather::Stanza::Iq
  end

  it 'must be importable' do
    doc = parse_stanza "<iq from='juliet@example.com/balcony' type='set' id='roster_4'></iq>"
    Blather::XMPPNode.import(doc.root).must_be_instance_of Blather::Stanza::Iq
  end

  it 'creates a new Iq stanza defaulted as a get' do
    Blather::Stanza::Iq.new.type.must_equal :get
  end

  it 'sets the id when created' do
    Blather::Stanza::Iq.new.id.wont_be_nil
  end

  it 'creates a new Stanza::Iq object on import' do
    Blather::Stanza::Iq.import(Blather::XMPPNode.new('iq')).must_be_kind_of Blather::Stanza::Iq
  end

  it 'creates a proper object based on its children' do
    n = Blather::XMPPNode.new('iq')
    n << Blather::XMPPNode.new('query', n.document)
    Blather::Stanza::Iq.import(n).must_be_kind_of Blather::Stanza::Iq::Query
  end

  it 'ensures type is one of Stanza::Iq::VALID_TYPES' do
    lambda { Blather::Stanza::Iq.new :invalid_type_name }.must_raise(Blather::ArgumentError)

    Blather::Stanza::Iq::VALID_TYPES.each do |valid_type|
      n = Blather::Stanza::Iq.new valid_type
      n.type.must_equal valid_type
    end
  end

  Blather::Stanza::Iq::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Blather::Stanza::Iq.new.must_respond_to :"#{valid_type}?"
    end
  end

  it 'removes the body when replying' do
    iq = Blather::Stanza::Iq.new :get, 'me@example.com'
    iq.from = 'them@example.com'
    iq << Blather::XMPPNode.new('query', iq.document)
    r = iq.reply
    r.children.empty?.must_equal true
  end
end
