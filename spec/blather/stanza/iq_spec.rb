require 'spec_helper'

describe Blather::Stanza::Iq do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:iq, nil)).to eq(Blather::Stanza::Iq)
  end

  it 'must be importable' do
    string = "<iq from='juliet@example.com/balcony' type='set' id='roster_4'></iq>"
    expect(Blather::XMPPNode.parse(string)).to be_instance_of Blather::Stanza::Iq
  end

  it 'creates a new Iq stanza defaulted as a get' do
    expect(Blather::Stanza::Iq.new.type).to eq(:get)
  end

  it 'sets the id when created' do
    expect(Blather::Stanza::Iq.new.id).not_to be_nil
  end

  it 'creates a new Stanza::Iq object on import' do
    expect(Blather::Stanza::Iq.import(Blather::XMPPNode.new('iq'))).to be_kind_of Blather::Stanza::Iq
  end

  it 'creates a proper object based on its children' do
    n = Blather::XMPPNode.new('iq')
    n << Blather::XMPPNode.new('query', n.document)
    expect(Blather::Stanza::Iq.import(n)).to be_kind_of Blather::Stanza::Iq::Query
  end

  it 'ensures type is one of Stanza::Iq::VALID_TYPES' do
    expect { Blather::Stanza::Iq.new :invalid_type_name }.to raise_error(Blather::ArgumentError)

    Blather::Stanza::Iq::VALID_TYPES.each do |valid_type|
      n = Blather::Stanza::Iq.new valid_type
      expect(n.type).to eq(valid_type)
    end
  end

  Blather::Stanza::Iq::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      expect(Blather::Stanza::Iq.new).to respond_to :"#{valid_type}?"
    end
  end

  it 'removes the body when replying' do
    iq = Blather::Stanza::Iq.new :get, 'me@example.com'
    iq.from = 'them@example.com'
    iq << Blather::XMPPNode.new('query', iq.document)
    r = iq.reply
    expect(r.children.empty?).to eq(true)
  end

  it 'does not remove the body when replying if we ask to keep it' do
    iq = Blather::Stanza::Iq.new :get, 'me@example.com'
    iq.from = 'them@example.com'
    iq << Blather::XMPPNode.new('query', iq.document)
    r = iq.reply :remove_children => false
    expect(r.children.empty?).to eq(false)
  end
end
