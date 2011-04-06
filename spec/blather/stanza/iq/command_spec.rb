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
    Blather::XMPPNode.class_from_registration(:command, 'http://jabber.org/protocol/commands').must_equal Blather::Stanza::Iq::Command
  end

  it 'must be importable' do
    Blather::XMPPNode.import(parse_stanza(command_xml).root).must_be_instance_of Blather::Stanza::Iq::Command
  end

  it 'ensures a command node is present on create' do
    c = Blather::Stanza::Iq::Command.new
    c.xpath('xmlns:command', :xmlns => Blather::Stanza::Iq::Command.registered_ns).wont_be_empty
  end

  it 'ensures a command node exists when calling #command' do
    c = Blather::Stanza::Iq::Command.new
    c.remove_children :command
    c.xpath('ns:command', :ns => Blather::Stanza::Iq::Command.registered_ns).must_be_empty

    c.command.wont_be_nil
    c.xpath('ns:command', :ns => Blather::Stanza::Iq::Command.registered_ns).wont_be_empty
  end

  Blather::Stanza::Iq::Command::VALID_ACTIONS.each do |valid_action|
    it "provides a helper (#{valid_action}?) for action #{valid_action}" do
      Blather::Stanza::Iq::Command.new.must_respond_to :"#{valid_action}?"
    end
  end

  Blather::Stanza::Iq::Command::VALID_STATUS.each do |valid_status|
    it "provides a helper (#{valid_status}?) for status #{valid_status}" do
      Blather::Stanza::Iq::Command.new.must_respond_to :"#{valid_status}?"
    end
  end

  Blather::Stanza::Iq::Command::VALID_NOTE_TYPES.each do |valid_note_type|
    it "provides a helper (#{valid_note_type}?) for note_type #{valid_note_type}" do
      Blather::Stanza::Iq::Command.new.must_respond_to :"#{valid_note_type}?"
    end
  end

  [:cancel, :execute, :complete, :next, :prev].each do |action|
    it "action can be set as \"#{action}\"" do
      c = Blather::Stanza::Iq::Command.new nil, nil, action
      c.action.must_equal action
    end
  end

  [:get, :set, :result, :error].each do |type|
    it "can be set as \"#{type}\"" do
      c = Blather::Stanza::Iq::Command.new type
      c.type.must_equal type
    end
  end

  it 'sets type to "result" on reply' do
    c = Blather::Stanza::Iq::Command.new
    c.type.must_equal :set
    reply = c.reply.type.must_equal :result
  end

  it 'sets type to "result" on reply!' do
    c = Blather::Stanza::Iq::Command.new
    c.type.must_equal :set
    c.reply!
    c.type.must_equal :result
  end

  it 'removes action on reply' do
    c = Blather::XMPPNode.import parse_stanza(command_xml).root
    c.action.must_equal :execute
    c.reply.action.must_equal nil
  end

  it 'removes action on reply!' do
    c = Blather::XMPPNode.import parse_stanza(command_xml).root
    c.action.must_equal :execute
    c.reply!
    c.action.must_equal nil
  end

  it 'can be registered under a namespace' do
    class CommandNs < Blather::Stanza::Iq::Command; register :command_ns, nil, 'command:ns'; end
    Blather::XMPPNode.class_from_registration(:command, 'command:ns').must_equal CommandNs
    c_ns = CommandNs.new
    c_ns.xpath('command').must_be_empty
    c_ns.xpath('ns:command', :ns => 'command:ns').size.must_equal 1

    c_ns.command
    c_ns.command
    c_ns.xpath('ns:command', :ns => 'command:ns').size.must_equal 1
  end

  it 'is constructed properly' do
    n = Blather::Stanza::Iq::Command.new :set, "node", :execute
    n.to = 'to@jid.com'
    n.find("/iq[@to='to@jid.com' and @type='set' and @id='#{n.id}']/ns:command[@node='node' and @action='execute']", :ns => Blather::Stanza::Iq::Command.registered_ns).wont_be_empty
  end

  it 'has an action attribute' do
    n = Blather::Stanza::Iq::Command.new
    n.action.must_equal :execute
    n.action = :cancel
    n.action.must_equal :cancel
  end

  it 'must default action to :execute on import' do
    n = Blather::XMPPNode.import(parse_stanza(command_xml).root)
    n.action.must_equal :execute
  end

  it 'has a status attribute' do
    n = Blather::Stanza::Iq::Command.new
    n.status.must_equal :executing
    n.status = :completed
    n.status.must_equal :completed
  end

  it 'has a sessionid attribute' do
    n = Blather::Stanza::Iq::Command.new
    n.sessionid.must_equal nil
    n.sessionid = "somerandomstring"
    n.sessionid.must_equal Digest::SHA1.hexdigest("somerandomstring")
  end

  it 'has a sessionid? attribute' do
    n = Blather::Stanza::Iq::Command.new
    n.sessionid?.must_equal false
    n.new_sessionid!
    n.sessionid?.must_equal true
  end

  it 'has an allowed_actions attribute' do
    n = Blather::XMPPNode.import parse_stanza(command_xml).root
    n.allowed_actions.must_equal [:execute]
    n.allowed_actions = [:next, :prev]
    (n.allowed_actions - [:next, :prev, :execute]).must_be_empty
    n.remove_allowed_actions!
    n.allowed_actions.must_equal [:execute]
    n.allowed_actions += [:next]
    (n.allowed_actions - [:next, :execute]).must_be_empty

    r = Blather::Stanza::Iq::Command.new
    r.allowed_actions.must_equal [:execute]
    r.allowed_actions += [:prev]
    (r.allowed_actions - [:prev, :execute]).must_be_empty
  end

  it 'has a primary_allowed_action attribute' do
    n = Blather::XMPPNode.import parse_stanza(command_xml).root
    n.primary_allowed_action.must_equal :execute
    n.primary_allowed_action = :next
    n.primary_allowed_action.must_equal :next
  end

  it 'has a note_type attribute' do
    n = Blather::Stanza::Iq::Command.new
    n.note_type.must_equal nil
    n.note_type = :info
    n.note_type.must_equal :info
  end

  it 'has a note_text attribute' do
    n = Blather::Stanza::Iq::Command.new
    n.note_text.must_equal nil
    n.note_text = "Some text"
    n.note_text.must_equal "Some text"
  end

  it 'makes a form child available' do
    n = Blather::XMPPNode.import(parse_stanza(command_xml).root)
    n.form.fields.size.must_equal 1
    n.form.fields.map { |f| f.class }.uniq.must_equal [Blather::Stanza::X::Field]
    n.form.must_be_instance_of Blather::Stanza::X

    r = Blather::Stanza::Iq::Command.new
    r.form.type = :form
    r.form.type.must_equal :form
  end

  it 'ensures the form child is a child of command' do
    r = Blather::Stanza::Iq::Command.new
    r.form
    r.command.xpath('ns:x', :ns => Blather::Stanza::X.registered_ns).wont_be_empty
    r.xpath('ns:x', :ns => Blather::Stanza::X.registered_ns).must_be_empty
  end
end
