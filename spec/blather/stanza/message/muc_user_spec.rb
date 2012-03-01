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
    c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns).wont_be_empty
  end

  it 'ensures a form node exists when calling #muc' do
    c = Blather::Stanza::Message::MUCUser.new
    c.remove_children :x
    c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns).must_be_empty

    c.muc_user.wont_be_nil
    c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns).wont_be_empty
  end

  it 'ensures the message type is :normal' do
    m = Blather::Stanza::Message::MUCUser.new
    m.normal?.must_equal true
  end

  it "must be able to set the password" do
    muc_user = Blather::Stanza::Message::MUCUser.new
    muc_user.password.must_equal nil
    muc_user.password = 'barbaz'
    muc_user.password.must_equal 'barbaz'
    muc_user.password = 'hello_world'
    muc_user.password.must_equal 'hello_world'
  end

  it "should not be an #invite?" do
    muc_user = Blather::Stanza::Message::MUCUser.new
    muc_user.invite?.must_equal false
  end

  describe "with an invite element" do
    it "should be an #invite?" do
      muc_user = Blather::XMPPNode.parse(muc_invite_xml)
      muc_user.invite?.must_equal true
    end

    it "should know the invite attributes properly" do
      muc_user = Blather::XMPPNode.parse(muc_invite_xml)
      muc_user.must_be_instance_of Blather::Stanza::Message::MUCUser
      invite = muc_user.invite
      invite.to.must_equal 'hecate@shakespeare.lit'
      invite.from.must_equal 'crone1@shakespeare.lit/desktop'
      invite.reason.must_equal 'Hey Hecate, this is the place for all good witches!'
      muc_user.password.must_equal 'foobar'
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      invite.to.must_equal nil
      invite.to = 'foo@bar.com'
      invite.to.must_equal 'foo@bar.com'
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      invite.from.must_equal nil
      invite.from = 'foo@bar.com'
      invite.from.must_equal 'foo@bar.com'
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      invite.reason.must_equal ''
      invite.reason = 'Please join'
      invite.reason.must_equal 'Please join'
    end
  end

  describe "with a decline element" do
    it "should be an #invite_decline?" do
      muc_user = Blather::XMPPNode.parse(muc_decline_xml)
      muc_user.must_be_instance_of Blather::Stanza::Message::MUCUser
      muc_user.invite_decline?.must_equal true
    end

    it "should know the decline attributes properly" do
      muc_user = Blather::XMPPNode.parse(muc_decline_xml)
      decline = muc_user.decline
      decline.to.must_equal 'crone1@shakespeare.lit'
      decline.from.must_equal 'hecate@shakespeare.lit'
      decline.reason.must_equal "Sorry, I'm too busy right now."
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      decline.to.must_equal nil
      decline.to = 'foo@bar.com'
      decline.to.must_equal 'foo@bar.com'
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      decline.from.must_equal nil
      decline.from = 'foo@bar.com'
      decline.from.must_equal 'foo@bar.com'
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      decline.reason.must_equal ''
      decline.reason = 'Please join'
      decline.reason.must_equal 'Please join'
    end
  end
end
