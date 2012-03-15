require 'spec_helper'

describe Blather::Stanza::Iq do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:iq, nil).should == Blather::Stanza::Iq
  end

  it 'must be importable' do
    string = "<iq from='juliet@example.com/balcony' type='set' id='roster_4'></iq>"
    Blather::XMPPNode.parse(string).should be_instance_of Blather::Stanza::Iq
  end

  it 'creates a new Iq stanza defaulted as a get' do
    Blather::Stanza::Iq.new.type.should == :get
  end

  it 'sets the id when created' do
    Blather::Stanza::Iq.new.id.should_not be_nil
  end

  it 'creates a new Stanza::Iq object on import' do
    Blather::Stanza::Iq.import(Blather::XMPPNode.new('iq')).should be_kind_of Blather::Stanza::Iq
  end

  it 'creates a proper object based on its children' do
    n = Blather::XMPPNode.new('iq')
    n << Blather::XMPPNode.new('query', n.document)
    Blather::Stanza::Iq.import(n).should be_kind_of Blather::Stanza::Iq::Query
  end

  it 'ensures type is one of Stanza::Iq::VALID_TYPES' do
    lambda { Blather::Stanza::Iq.new :invalid_type_name }.should raise_error(Blather::ArgumentError)

    Blather::Stanza::Iq::VALID_TYPES.each do |valid_type|
      n = Blather::Stanza::Iq.new valid_type
      n.type.should == valid_type
    end
  end

  Blather::Stanza::Iq::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Blather::Stanza::Iq.new.should respond_to :"#{valid_type}?"
    end
  end

  it 'removes the body when replying' do
    iq = Blather::Stanza::Iq.new :get, 'me@example.com'
    iq.from = 'them@example.com'
    iq << Blather::XMPPNode.new('query', iq.document)
    r = iq.reply
    r.children.empty?.should == true
  end

  it 'does not remove the body when replying if we ask to keep it' do
    iq = Blather::Stanza::Iq.new :get, 'me@example.com'
    iq.from = 'them@example.com'
    iq << Blather::XMPPNode.new('query', iq.document)
    r = iq.reply :remove_children => false
    r.children.empty?.should == false
  end
end
