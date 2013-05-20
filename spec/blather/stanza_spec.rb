require 'spec_helper'

describe Blather::Stanza do
  it 'provides .next_id helper for generating new IDs' do
    proc { Blather::Stanza.next_id }.should change Blather::Stanza, :next_id
  end

  it 'provides a handler registration mechanism' do
    class Registration < Blather::Stanza; register :handler_test, :handler, 'test:namespace'; end
    Registration.handler_hierarchy.should include :handler_test
    Blather::Stanza.handler_list.should include :handler_test
  end

  it 'can register based on handler' do
    class RegisterHandler < Blather::Stanza; register :register_handler; end
    Blather::Stanza.class_from_registration(:register_handler, nil).should == RegisterHandler
  end

  it 'can register based on given name' do
    class RegisterName < Blather::Stanza; register :handler, :registered_name; end
    Blather::Stanza.class_from_registration(:registered_name, nil).should == RegisterName
  end

  it 'can register subclass handlers' do
    class SuperClassRegister < Blather::Stanza; register :super_class; end
    class SubClassRegister < SuperClassRegister; register :sub_class; end
    SuperClassRegister.handler_hierarchy.should_not include :sub_class
    SubClassRegister.handler_hierarchy.should include :super_class
  end

  it 'can import a node' do
    s = Blather::Stanza.import Blather::XMPPNode.new('foo')
    s.node_name.should == 'foo'
  end

  it 'provides an #error? helper' do
    s = Blather::Stanza.new('message')
    s.error?.should == false
    s.type = :error
    s.error?.should == true
  end

  it 'will generate a reply' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')

    r = s.reply
    r.object_id.should_not equal s.object_id
    r.from.should == t
    r.to.should == f
  end

  it 'convert to a reply' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')

    r = s.reply!
    r.object_id.should == s.object_id
    r.from.should == t
    r.to.should == f
  end

  it 'does not remove the body when replying' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')
    s << Blather::XMPPNode.new('query', s.document)
    r = s.reply
    r.children.empty?.should == false
  end

  it 'removes the body when replying if we ask to remove it' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')
    s << Blather::XMPPNode.new('query', s.document)
    r = s.reply :remove_children => true
    r.children.empty?.should == true
  end

  it 'provides "attr_accessor" for id' do
    s = Blather::Stanza.new('message')
    s.id.should be_nil
    s[:id].should be_nil

    s.id = '123'
    s.id.should == '123'
    s[:id].should == '123'
  end

  it 'provides "attr_accessor" for to' do
    s = Blather::Stanza.new('message')
    s.to.should be_nil
    s[:to].should be_nil

    s.to = Blather::JID.new('n@d/r')
    s.to.should_not be_nil
    s.to.should be_kind_of Blather::JID

    s[:to].should_not be_nil
    s[:to].should == 'n@d/r'
  end

  it 'provides "attr_accessor" for from' do
    s = Blather::Stanza.new('message')
    s.from.should be_nil
    s[:from].should be_nil

    s.from = Blather::JID.new('n@d/r')
    s.from.should_not be_nil
    s.from.should be_kind_of Blather::JID

    s[:from].should_not be_nil
    s[:from].should == 'n@d/r'
  end

  it 'provides "attr_accessor" for type' do
    s = Blather::Stanza.new('message')
    s.type.should be_nil
    s[:type].should be_nil

    s.type = 'testing'
    s.type.should_not be_nil
    s[:type].should_not be_nil
  end

  it 'can be converted into an error by error name' do
    s = Blather::Stanza.new('message')
    err = s.as_error 'internal-server-error', 'cancel'
    err.name.should == :internal_server_error
  end
end
