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
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns)).not_to be_empty
  end

  it 'ensures a form node exists when calling #muc' do
    c = Blather::Stanza::Message::MUCUser.new
    c.remove_children :x
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns)).to be_empty

    expect(c.muc_user).not_to be_nil
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Message::MUCUser.registered_ns)).not_to be_empty
  end

  it 'ensures the message type is :normal' do
    m = Blather::Stanza::Message::MUCUser.new
    expect(m.normal?).to eq(true)
  end

  it "must be able to set the password" do
    muc_user = Blather::Stanza::Message::MUCUser.new
    expect(muc_user.password).to eq(nil)
    muc_user.password = 'barbaz'
    expect(muc_user.password).to eq('barbaz')
    muc_user.password = 'hello_world'
    expect(muc_user.password).to eq('hello_world')
  end

  it "should not be an #invite?" do
    muc_user = Blather::Stanza::Message::MUCUser.new
    expect(muc_user.invite?).to eq(false)
  end

  describe "with an invite element" do
    it "should be an #invite?" do
      muc_user = Blather::XMPPNode.parse(muc_invite_xml)
      expect(muc_user.invite?).to eq(true)
    end

    it "should know the invite attributes properly" do
      muc_user = Blather::XMPPNode.parse(muc_invite_xml)
      expect(muc_user).to be_instance_of Blather::Stanza::Message::MUCUser
      invite = muc_user.invite
      expect(invite.to).to eq('hecate@shakespeare.lit')
      expect(invite.from).to eq('crone1@shakespeare.lit/desktop')
      expect(invite.reason).to eq('Hey Hecate, this is the place for all good witches!')
      expect(muc_user.password).to eq('foobar')
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      expect(invite.to).to eq(nil)
      invite.to = 'foo@bar.com'
      expect(invite.to).to eq('foo@bar.com')
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      expect(invite.from).to eq(nil)
      invite.from = 'foo@bar.com'
      expect(invite.from).to eq('foo@bar.com')
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      invite = muc_user.invite
      expect(invite.reason).to eq('')
      invite.reason = 'Please join'
      expect(invite.reason).to eq('Please join')
    end
  end

  describe "with a decline element" do
    it "should be an #invite_decline?" do
      muc_user = Blather::XMPPNode.parse(muc_decline_xml)
      expect(muc_user).to be_instance_of Blather::Stanza::Message::MUCUser
      expect(muc_user.invite_decline?).to eq(true)
    end

    it "should know the decline attributes properly" do
      muc_user = Blather::XMPPNode.parse(muc_decline_xml)
      decline = muc_user.decline
      expect(decline.to).to eq('crone1@shakespeare.lit')
      expect(decline.from).to eq('hecate@shakespeare.lit')
      expect(decline.reason).to eq("Sorry, I'm too busy right now.")
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      expect(decline.to).to eq(nil)
      decline.to = 'foo@bar.com'
      expect(decline.to).to eq('foo@bar.com')
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      expect(decline.from).to eq(nil)
      decline.from = 'foo@bar.com'
      expect(decline.from).to eq('foo@bar.com')
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Message::MUCUser.new
      decline = muc_user.decline
      expect(decline.reason).to eq('')
      decline.reason = 'Please join'
      expect(decline.reason).to eq('Please join')
    end
  end
end
