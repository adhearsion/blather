require 'spec_helper'

def command_xml
  <<-XML
  <iq type='result'
      from='catalog.shakespeare.lit'
      to='romeo@montague.net/orchard'
      id='form2'>
    <command xmlns='http://jabber.org/protocol/commands'
             node='node1'
             sessionid='dqjiodmqlmakm'>
      <x xmlns='jabber:x:data' type='form'>
        <field var='field-name' type='text-single' label='description' />
      </x>
    </command>
  </iq>
  XML
end

describe Blather::Stanza::Iq::Command do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:command, 'http://jabber.org/protocol/commands')).to eq(Blather::Stanza::Iq::Command)
  end

  it 'must be importable' do
    expect(Blather::XMPPNode.parse(command_xml)).to be_instance_of Blather::Stanza::Iq::Command
  end

  it 'ensures a command node is present on create' do
    c = Blather::Stanza::Iq::Command.new
    expect(c.xpath('xmlns:command', :xmlns => Blather::Stanza::Iq::Command.registered_ns)).not_to be_empty
  end

  it 'ensures a command node exists when calling #command' do
    c = Blather::Stanza::Iq::Command.new
    c.remove_children :command
    expect(c.xpath('ns:command', :ns => Blather::Stanza::Iq::Command.registered_ns)).to be_empty

    expect(c.command).not_to be_nil
    expect(c.xpath('ns:command', :ns => Blather::Stanza::Iq::Command.registered_ns)).not_to be_empty
  end

  Blather::Stanza::Iq::Command::VALID_ACTIONS.each do |valid_action|
    it "provides a helper (#{valid_action}?) for action #{valid_action}" do
      expect(Blather::Stanza::Iq::Command.new).to respond_to :"#{valid_action}?"
    end
  end

  Blather::Stanza::Iq::Command::VALID_STATUS.each do |valid_status|
    it "provides a helper (#{valid_status}?) for status #{valid_status}" do
      expect(Blather::Stanza::Iq::Command.new).to respond_to :"#{valid_status}?"
    end
  end

  Blather::Stanza::Iq::Command::VALID_NOTE_TYPES.each do |valid_note_type|
    it "provides a helper (#{valid_note_type}?) for note_type #{valid_note_type}" do
      expect(Blather::Stanza::Iq::Command.new).to respond_to :"#{valid_note_type}?"
    end
  end

  [:cancel, :execute, :complete, :next, :prev].each do |action|
    it "action can be set as \"#{action}\"" do
      c = Blather::Stanza::Iq::Command.new nil, nil, action
      expect(c.action).to eq(action)
    end
  end

  [:get, :set, :result, :error].each do |type|
    it "can be set as \"#{type}\"" do
      c = Blather::Stanza::Iq::Command.new type
      expect(c.type).to eq(type)
    end
  end

  it 'sets type to "result" on reply' do
    c = Blather::Stanza::Iq::Command.new
    expect(c.type).to eq(:set)
    reply = expect(c.reply.type).to eq(:result)
  end

  it 'sets type to "result" on reply!' do
    c = Blather::Stanza::Iq::Command.new
    expect(c.type).to eq(:set)
    c.reply!
    expect(c.type).to eq(:result)
  end

  it 'removes action on reply' do
    c = Blather::XMPPNode.parse command_xml
    expect(c.action).to eq(:execute)
    expect(c.reply.action).to eq(nil)
  end

  it 'removes action on reply!' do
    c = Blather::XMPPNode.parse command_xml
    expect(c.action).to eq(:execute)
    c.reply!
    expect(c.action).to eq(nil)
  end

  it 'can be registered under a namespace' do
    class CommandNs < Blather::Stanza::Iq::Command; register :command_ns, nil, 'command:ns'; end
    expect(Blather::XMPPNode.class_from_registration(:command, 'command:ns')).to eq(CommandNs)
    c_ns = CommandNs.new
    expect(c_ns.xpath('command')).to be_empty
    expect(c_ns.xpath('ns:command', :ns => 'command:ns').size).to eq(1)

    c_ns.command
    c_ns.command
    expect(c_ns.xpath('ns:command', :ns => 'command:ns').size).to eq(1)
  end

  it 'is constructed properly' do
    n = Blather::Stanza::Iq::Command.new :set, "node", :execute
    n.to = 'to@jid.com'
    expect(n.find("/iq[@to='to@jid.com' and @type='set' and @id='#{n.id}']/ns:command[@node='node' and @action='execute']", :ns => Blather::Stanza::Iq::Command.registered_ns)).not_to be_empty
  end

  it 'has an action attribute' do
    n = Blather::Stanza::Iq::Command.new
    expect(n.action).to eq(:execute)
    n.action = :cancel
    expect(n.action).to eq(:cancel)
  end

  it 'must default action to :execute on import' do
    n = Blather::XMPPNode.parse(command_xml)
    expect(n.action).to eq(:execute)
  end

  it 'has a status attribute' do
    n = Blather::Stanza::Iq::Command.new
    expect(n.status).to eq(:executing)
    n.status = :completed
    expect(n.status).to eq(:completed)
  end

  it 'has a sessionid attribute' do
    n = Blather::Stanza::Iq::Command.new
    expect(n.sessionid).to eq(nil)
    n.sessionid = "somerandomstring"
    expect(n.sessionid).to eq(Digest::SHA1.hexdigest("somerandomstring"))
  end

  it 'has a sessionid? attribute' do
    n = Blather::Stanza::Iq::Command.new
    expect(n.sessionid?).to eq(false)
    n.new_sessionid!
    expect(n.sessionid?).to eq(true)
  end

  it 'has an allowed_actions attribute' do
    n = Blather::XMPPNode.parse command_xml
    expect(n.allowed_actions).to eq([:execute])
    n.allowed_actions = [:next, :prev]
    expect(n.allowed_actions - [:next, :prev, :execute]).to be_empty
    n.remove_allowed_actions!
    expect(n.allowed_actions).to eq([:execute])
    n.allowed_actions += [:next]
    expect(n.allowed_actions - [:next, :execute]).to be_empty

    r = Blather::Stanza::Iq::Command.new
    expect(r.allowed_actions).to eq([:execute])
    r.allowed_actions += [:prev]
    expect(r.allowed_actions - [:prev, :execute]).to be_empty
  end

  it 'has a primary_allowed_action attribute' do
    n = Blather::XMPPNode.parse command_xml
    expect(n.primary_allowed_action).to eq(:execute)
    n.primary_allowed_action = :next
    expect(n.primary_allowed_action).to eq(:next)
  end

  it 'has a note_type attribute' do
    n = Blather::Stanza::Iq::Command.new
    expect(n.note_type).to eq(nil)
    n.note_type = :info
    expect(n.note_type).to eq(:info)
  end

  it 'has a note_text attribute' do
    n = Blather::Stanza::Iq::Command.new
    expect(n.note_text).to eq(nil)
    n.note_text = "Some text"
    expect(n.note_text).to eq("Some text")
  end

  it 'makes a form child available' do
    n = Blather::XMPPNode.parse(command_xml)
    expect(n.form.fields.size).to eq(1)
    expect(n.form.fields.map { |f| f.class }.uniq).to eq([Blather::Stanza::X::Field])
    expect(n.form).to be_instance_of Blather::Stanza::X

    r = Blather::Stanza::Iq::Command.new
    r.form.type = :form
    expect(r.form.type).to eq(:form)
  end

  it 'ensures the form child is a child of command' do
    r = Blather::Stanza::Iq::Command.new
    r.form
    expect(r.command.xpath('ns:x', :ns => Blather::Stanza::X.registered_ns)).not_to be_empty
    expect(r.xpath('ns:x', :ns => Blather::Stanza::X.registered_ns)).to be_empty
  end
end
