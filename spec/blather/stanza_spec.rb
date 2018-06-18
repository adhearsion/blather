require 'spec_helper'

describe Blather::Stanza do
  it 'provides .next_id helper for generating new IDs' do
    expect { Blather::Stanza.next_id }.to change Blather::Stanza, :next_id
  end

  it 'provides a handler registration mechanism' do
    class Registration < Blather::Stanza; register :handler_test, :handler, 'test:namespace'; end
    expect(Registration.handler_hierarchy).to include :handler_test
    expect(Blather::Stanza.handler_list).to include :handler_test
  end

  it 'can register based on handler' do
    class RegisterHandler < Blather::Stanza; register :register_handler; end
    expect(Blather::Stanza.class_from_registration(:register_handler, nil)).to eq(RegisterHandler)
  end

  it 'can register based on given name' do
    class RegisterName < Blather::Stanza; register :handler, :registered_name; end
    expect(Blather::Stanza.class_from_registration(:registered_name, nil)).to eq(RegisterName)
  end

  it 'can register subclass handlers' do
    class SuperClassRegister < Blather::Stanza; register :super_class; end
    class SubClassRegister < SuperClassRegister; register :sub_class; end
    expect(SuperClassRegister.handler_hierarchy).not_to include :sub_class
    expect(SubClassRegister.handler_hierarchy).to include :super_class
  end

  it 'can import a node' do
    s = Blather::Stanza.import Blather::XMPPNode.new('foo')
    expect(s.element_name).to eq('foo')
  end

  it 'provides an #error? helper' do
    s = Blather::Stanza.new('message')
    expect(s.error?).to eq(false)
    s.type = :error
    expect(s.error?).to eq(true)
  end

  it 'will generate a reply' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')

    r = s.reply
    expect(r.object_id).not_to equal s.object_id
    expect(r.from).to eq(t)
    expect(r.to).to eq(f)
  end

  it 'convert to a reply' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')

    r = s.reply!
    expect(r.object_id).to eq(s.object_id)
    expect(r.from).to eq(t)
    expect(r.to).to eq(f)
  end

  it 'does not remove the body when replying' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')
    s << Blather::XMPPNode.new('query', s.document)
    r = s.reply
    expect(r.children.empty?).to eq(false)
  end

  it 'removes the body when replying if we ask to remove it' do
    s = Blather::Stanza.new('message')
    s.from = f = Blather::JID.new('n@d/r')
    s.to = t = Blather::JID.new('d@n/r')
    s << Blather::XMPPNode.new('query', s.document)
    r = s.reply :remove_children => true
    expect(r.children.empty?).to eq(true)
  end

  it 'provides "attr_accessor" for id' do
    s = Blather::Stanza.new('message')
    expect(s.id).to be_nil
    expect(s[:id]).to be_nil

    s.id = '123'
    expect(s.id).to eq('123')
    expect(s[:id]).to eq('123')
  end

  it 'provides "attr_accessor" for to' do
    s = Blather::Stanza.new('message')
    expect(s.to).to be_nil
    expect(s[:to]).to be_nil

    s.to = Blather::JID.new('n@d/r')
    expect(s.to).not_to be_nil
    expect(s.to).to be_kind_of Blather::JID

    expect(s[:to]).not_to be_nil
    expect(s[:to]).to eq('n@d/r')
  end

  it 'provides "attr_accessor" for from' do
    s = Blather::Stanza.new('message')
    expect(s.from).to be_nil
    expect(s[:from]).to be_nil

    s.from = Blather::JID.new('n@d/r')
    expect(s.from).not_to be_nil
    expect(s.from).to be_kind_of Blather::JID

    expect(s[:from]).not_to be_nil
    expect(s[:from]).to eq('n@d/r')
  end

  it 'provides "attr_accessor" for type' do
    s = Blather::Stanza.new('message')
    expect(s.type).to be_nil
    expect(s[:type]).to be_nil

    s.type = 'testing'
    expect(s.type).not_to be_nil
    expect(s[:type]).not_to be_nil
  end

  it 'can be converted into an error by error name' do
    s = Blather::Stanza.new('message')
    err = s.as_error 'internal-server-error', 'cancel'
    expect(err.name).to eq(:internal_server_error)
  end
end
