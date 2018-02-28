require 'spec_helper'

describe Blather::Stanza::Presence do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:presence, nil)).to eq(Blather::Stanza::Presence)
  end

  it 'must be importable' do
    expect(Blather::XMPPNode.parse('<presence type="probe"/>')).to be_instance_of Blather::Stanza::Presence
  end

  it 'ensures type is one of Blather::Stanza::Presence::VALID_TYPES' do
    presence = Blather::Stanza::Presence.new
    expect { presence.type = :invalid_type_name }.to raise_error(Blather::ArgumentError)

    Blather::Stanza::Presence::VALID_TYPES.each do |valid_type|
      presence.type = valid_type
      expect(presence.type).to eq(valid_type)
    end
  end

  Blather::Stanza::Presence::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      expect(Blather::Stanza::Presence.new).to respond_to :"#{valid_type}?"
    end

    it "returns true on call to (#{valid_type}?) if type == #{valid_type}" do
      method = "#{valid_type}?".to_sym
      pres = Blather::Stanza::Presence.new
      pres.type = valid_type
      expect(pres).to respond_to method
      expect(pres.__send__(method)).to eq(true)
    end
  end

  it 'creates a C object when importing a node with a c child' do
    string = <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <c xmlns='http://jabber.org/protocol/caps'
           hash='sha-1'
           node='http://www.chatopus.com'
           ver='zHyEOgxTrkpSdGcQKH8EFPLsriY='/>
      </presence>
    XML
    s = Blather::Stanza::Presence.parse string
    expect(s).to be_kind_of Blather::Stanza::Presence::C::InstanceMethods
    expect(s.node).to eq('http://www.chatopus.com')
    expect(s.handler_hierarchy).to include(:c)
  end

  it 'creates a Status object when importing a node with type == nil' do
    s = Blather::Stanza::Presence.parse('<presence/>')
    expect(s).to be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
    expect(s.state).to eq(:available)
    expect(s.handler_hierarchy).to include(Blather::Stanza::Presence::Status.registered_name.to_sym)
  end

  it 'creates a Status object when importing a node with type == "unavailable"' do
    s = Blather::Stanza::Presence.parse('<presence type="unavailable"/>')
    expect(s).to be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
    expect(s.state).to eq(:unavailable)
    expect(s.handler_hierarchy).to include(Blather::Stanza::Presence::Status.registered_name.to_sym)
  end

  it 'creates a Subscription object when importing a node with type == "subscribe"' do
    s = Blather::Stanza::Presence.parse('<presence type="subscribe"/>')
    expect(s).to be_kind_of Blather::Stanza::Presence::Subscription::InstanceMethods
    expect(s.type).to eq(:subscribe)
    expect(s.handler_hierarchy).to include(Blather::Stanza::Presence::Subscription.registered_name.to_sym)
  end

  it 'creates a MUC object when importing a node with a form in the MUC namespace' do
    string = <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <x xmlns='http://jabber.org/protocol/muc'/>
      </presence>
    XML
    s = Blather::Stanza::Presence.parse string
    expect(s).to be_kind_of Blather::Stanza::Presence::MUC::InstanceMethods
  end

  it 'creates a MUCUser object when importing a node with a form in the MUC#user namespace' do
    string = <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <x xmlns='http://jabber.org/protocol/muc#user'/>
      </presence>
    XML
    s = Blather::Stanza::Presence.parse string
    expect(s).to be_kind_of Blather::Stanza::Presence::MUCUser::InstanceMethods
  end

  it 'creates a Presence object when importing a node with type equal to something unknown' do
    string = "<presence from='bard@shakespeare.lit/globe' type='foo'/>"
    s = Blather::Stanza::Presence.parse string
    expect(s).to be_kind_of Blather::Stanza::Presence
    expect(s.type).to eq(:foo)
    expect(s.handler_hierarchy).to include(Blather::Stanza::Presence.registered_name.to_sym)
  end

  it 'behaves like a C, a Status, and a MUCUser when all types of children are present' do
    string = <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <show>chat</show>
        <c xmlns='http://jabber.org/protocol/caps'
           hash='sha-1'
           node='http://www.chatopus.com'
           ver='zHyEOgxTrkpSdGcQKH8EFPLsriY='/>
        <x xmlns='http://jabber.org/protocol/muc#user'>
          <item affiliation='none'
                jid='hag66@shakespeare.lit/pda'
                role='participant'/>
          <status code='100'/>
          <status code='110'/>
          <password>foobar</password>
        </x>
      </presence>
    XML
    s = Blather::Stanza::Presence.parse string
    expect(s.state).to eq(:chat)
    expect(s.node).to eq('http://www.chatopus.com')
    expect(s.role).to eq(:participant)
    expect(s.handler_hierarchy).to include(Blather::Stanza::Presence::C.registered_name.to_sym)
    expect(s.handler_hierarchy).to include(Blather::Stanza::Presence::Status.registered_name.to_sym)
  end

  it "handle stanzas with nested elements that don't have a decorator module or are not stanzas" do
    string = <<-XML
      <presence from="me@gmx.net/GMX MultiMessenger" to="receiver@gmail.com/480E24CF" lang="de">
        <show>away</show>
        <priority>0</priority>
        <nick xmlns="http://jabber.org/protocol/nick">Me</nick>
        <x xmlns="jabber:x:data" type="submit">
          <field var="FORM_TYPE" type="hidden">
            <value>http://jabber.org/protocol/profile</value>
          </field>
          <field var="x-sip_capabilities" type="text-single">
            <value>19</value>
          </field>
        </x>
        <x xmlns="vcard-temp:x:update">
          <photo/>
        </x>
        <ignore xmlns="http://gmx.net/protocol/gateway"/>
        <delay xmlns="urn:xmpp:delay" from="me@gmx.net/GMX MultiMessenger" stamp="2013-08-26T22:18:41Z"/>
        <x xmlns="jabber:x:delay" stamp="20130826T22:18:41"/>
      </presence>
    XML
    s = Blather::Stanza::Presence.parse string
    expect(s).to be_a Blather::Stanza::Presence
  end
end
