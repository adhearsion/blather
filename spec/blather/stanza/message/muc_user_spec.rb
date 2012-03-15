require 'spec_helper'

def muc_invite_xml
  <<-XML
  <message
        from='coven@chat.shakespeare.lit'
        id='nzd143v8'
        to='hecate@shakespeare.lit'>
      <x xmlns='http://jabber.org/protocol/muc#user'>
        <invite to='hecate@shakespeare.lit' from='crone1@shakespeare.lit/desktop'>
          <reason>
            Hey Hecate, this is the place for all good witches!
          </reason>
        </invite>
        <password>foobar</password>
      </x>
    </message>
  XML
end

def muc_decline_xml
  <<-XML
    <message
        from='hecate@shakespeare.lit/broom'
        id='jk2vs61v'
        to='coven@chat.shakespeare.lit'>
      <x xmlns='http://jabber.org/protocol/muc#user'>
        <decline to='crone1@shakespeare.lit' from='hecate@shakespeare.lit'>
          <reason>
            Sorry, I'm too busy right now.
          </reason>
        </decline>
      </x>
    </message>
  XML
end

describe 'Blather::Stanza::Message::MUCUser' do
  it 'ensures a form node is present on create' do
    c = Blather::Stanza::Message::MUCUser.new
    c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns).should_not be_empty
  end

  it 'ensures a form node exists when calling #muc' do
    c = Blather::Stanza::Message::MUCUser.new
    c.remove_children :x
    c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns).should be_empty

    c.muc_user.should_not be_nil
    c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns).should_not be_empty
  end

  it 'ensures the message type is :normal' do
    m = Blather::Stanza::Message::MUCUser.new
    m.normal?.should == true
  end

  it "must be able to set the password" do
    muc_user = Blather::Stanza::Message::MUCUser.new
    muc_user.password.should == nil
    muc_user.password = 'barbaz'
    muc_user.password.should == 'barbaz'
    muc_user.password = 'hello_world'
    muc_user.password.should == 'hello_world'
  end

  it "should not be an #invite?" do
    muc_user = Blather::Stanza::Message::MUCUser.new
    muc_user.invite?.should == false
  end

  describe "with an invite element" do
    it "should be an #invite?" do
      muc_user = Blather::XMPPNode.parse(muc_invite_xml)
      muc_user.invite?.should == true
    end

    it "should know the invite attributes properly" do
      muc_user = Blather::XMPPNode.parse(muc_invite_xml)
      muc_user.should be_instance_of Blather::Stanza::Message::MUCUser
      invite = muc_user.invite
      invite.to.should == 'hecate@shakespeare.lit'
      invite.from.should == 'crone1@shakespeare.lit/desktop'
      invite.reason.should == 'Hey Hecate, this is the place for all good witches!'
      muc_user.password.should == 'foobar'
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      invite.to.should == nil
      invite.to = 'foo@bar.com'
      invite.to.should == 'foo@bar.com'
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      invite.from.should == nil
      invite.from = 'foo@bar.com'
      invite.from.should == 'foo@bar.com'
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      invite.reason.should == ''
      invite.reason = 'Please join'
      invite.reason.should == 'Please join'
    end
  end

  describe "with a decline element" do
    it "should be an #invite_decline?" do
      muc_user = Blather::XMPPNode.parse(muc_decline_xml)
      muc_user.should be_instance_of Blather::Stanza::Message::MUCUser
      muc_user.invite_decline?.should == true
    end

    it "should know the decline attributes properly" do
      muc_user = Blather::XMPPNode.parse(muc_decline_xml)
      decline = muc_user.decline
      decline.to.should == 'crone1@shakespeare.lit'
      decline.from.should == 'hecate@shakespeare.lit'
      decline.reason.should == "Sorry, I'm too busy right now."
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      decline.to.should == nil
      decline.to = 'foo@bar.com'
      decline.to.should == 'foo@bar.com'
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      decline.from.should == nil
      decline.from = 'foo@bar.com'
      decline.from.should == 'foo@bar.com'
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      decline.reason.should == ''
      decline.reason = 'Please join'
      decline.reason.should == 'Please join'
    end
  end
end
