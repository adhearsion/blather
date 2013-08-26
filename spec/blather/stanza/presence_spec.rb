require 'spec_helper'

describe Blather::Stanza::Presence do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:presence, nil).should == Blather::Stanza::Presence
  end

  it 'must be importable' do
    Blather::XMPPNode.parse('<presence type="probe"/>').should be_instance_of Blather::Stanza::Presence
  end

  it 'ensures type is one of Blather::Stanza::Presence::VALID_TYPES' do
    presence = Blather::Stanza::Presence.new
    lambda { presence.type = :invalid_type_name }.should raise_error(Blather::ArgumentError)

    Blather::Stanza::Presence::VALID_TYPES.each do |valid_type|
      presence.type = valid_type
      presence.type.should == valid_type
    end
  end

  Blather::Stanza::Presence::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Blather::Stanza::Presence.new.should respond_to :"#{valid_type}?"
    end

    it "returns true on call to (#{valid_type}?) if type == #{valid_type}" do
      method = "#{valid_type}?".to_sym
      pres = Blather::Stanza::Presence.new
      pres.type = valid_type
      pres.should respond_to method
      pres.__send__(method).should == true
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
    s.should be_kind_of Blather::Stanza::Presence::C::InstanceMethods
    s.node.should == 'http://www.chatopus.com'
    s.handler_hierarchy.should include(:c)
  end

  it 'creates a Status object when importing a node with type == nil' do
    s = Blather::Stanza::Presence.parse('<presence/>')
    s.should be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
    s.state.should == :available
    s.handler_hierarchy.should include(Blather::Stanza::Presence::Status.registered_name.to_sym)
  end

  it 'creates a Status object when importing a node with type == "unavailable"' do
    s = Blather::Stanza::Presence.parse('<presence type="unavailable"/>')
    s.should be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
    s.state.should == :unavailable
    s.handler_hierarchy.should include(Blather::Stanza::Presence::Status.registered_name.to_sym)
  end

  it 'creates a Subscription object when importing a node with type == "subscribe"' do
    s = Blather::Stanza::Presence.parse('<presence type="subscribe"/>')
    s.should be_kind_of Blather::Stanza::Presence::Subscription::InstanceMethods
    s.type.should == :subscribe
    s.handler_hierarchy.should include(Blather::Stanza::Presence::Subscription.registered_name.to_sym)
  end

  it 'creates a MUC object when importing a node with a form in the MUC namespace' do
    string = <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <x xmlns='http://jabber.org/protocol/muc'/>
      </presence>
    XML
    s = Blather::Stanza::Presence.parse string
    s.should be_kind_of Blather::Stanza::Presence::MUC::InstanceMethods
  end

  it 'creates a MUCUser object when importing a node with a form in the MUC#user namespace' do
    string = <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <x xmlns='http://jabber.org/protocol/muc#user'/>
      </presence>
    XML
    s = Blather::Stanza::Presence.parse string
    s.should be_kind_of Blather::Stanza::Presence::MUCUser::InstanceMethods
  end

  it 'creates a Presence object when importing a node with type equal to something unknown' do
    string = "<presence from='bard@shakespeare.lit/globe' type='foo'/>"
    s = Blather::Stanza::Presence.parse string
    s.should be_kind_of Blather::Stanza::Presence
    s.type.should == :foo
    s.handler_hierarchy.should include(Blather::Stanza::Presence.registered_name.to_sym)
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
    s.state.should == :chat
    s.node.should == 'http://www.chatopus.com'
    s.role.should == :participant
    s.handler_hierarchy.should include(Blather::Stanza::Presence::C.registered_name.to_sym)
    s.handler_hierarchy.should include(Blather::Stanza::Presence::Status.registered_name.to_sym)
  end

  it 'handle message with nested X element without throwing exception uninitialized constant Blather::Stanza::X::InstanceMethods' do
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
    Blather::Stanza::Presence.parse string
  end
end
