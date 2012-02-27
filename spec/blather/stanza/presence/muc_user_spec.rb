require 'spec_helper'

def muc_user_xml
  <<-XML
    <presence from='hag66@shakespeare.lit/pda'
              id='n13mt3l'
              to='coven@chat.shakespeare.lit/thirdwitch'>
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
end

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

describe 'Blather::Stanza::Presence::MUCUser' do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:x, 'http://jabber.org/protocol/muc#user' ).must_equal Blather::Stanza::Presence::MUCUser
  end

  it 'must be importable' do
    muc_user = Blather::XMPPNode.import(parse_stanza(muc_user_xml).root)
    muc_user.must_be_instance_of Blather::Stanza::Presence::MUCUser
    muc_user.affiliation.must_equal :none
    muc_user.jid.must_equal 'hag66@shakespeare.lit/pda'
    muc_user.role.must_equal :participant
    muc_user.status_codes.must_equal [100, 110]
    muc_user.password.must_equal 'foobar'
  end

  it 'ensures a form node is present on create' do
    c = Blather::Stanza::Presence::MUCUser.new
    c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns).wont_be_empty
  end

  it 'ensures a form node exists when calling #muc' do
    c = Blather::Stanza::Presence::MUCUser.new
    c.remove_children :x
    c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns).must_be_empty

    c.muc_user.wont_be_nil
    c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns).wont_be_empty
  end

  it "must be able to set the affiliation" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.affiliation.must_equal nil
    muc_user.affiliation = :none
    muc_user.affiliation.must_equal :none
  end

  it "must be able to set the role" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.role.must_equal nil
    muc_user.role = :participant
    muc_user.role.must_equal :participant
  end

  it "must be able to set the jid" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.jid.must_equal nil
    muc_user.jid = 'foo@bar.com'
    muc_user.jid.must_equal 'foo@bar.com'
  end

  it "must be able to set the status codes" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.status_codes.must_equal []
    muc_user.status_codes = [100, 110]
    muc_user.status_codes.must_equal [100, 110]
    muc_user.status_codes = [500]
    muc_user.status_codes.must_equal [500]
  end

  it "must be able to set the password" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.password.must_equal nil
    muc_user.password = 'barbaz'
    muc_user.password.must_equal 'barbaz'
    muc_user.password = 'hello_world'
    muc_user.password.must_equal 'hello_world'
  end

  it "should not be an #invite?" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.invite?.must_equal false
  end

  describe "with an invite element" do
    it "should be an #invite?" do
      muc_user = Blather::XMPPNode.import(parse_stanza(muc_invite_xml).root)
      muc_user.invite?.must_equal true
    end

    it "should know the invite attributes properly" do
      muc_user = Blather::XMPPNode.import(parse_stanza(muc_invite_xml).root)
      invite = muc_user.invite
      invite.to.must_equal 'hecate@shakespeare.lit'
      invite.from.must_equal 'crone1@shakespeare.lit/desktop'
      invite.reason.must_equal 'Hey Hecate, this is the place for all good witches!'
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Presence::MUCUser.new
      invite = muc_user.invite
      invite.to.must_equal nil
      invite.to = 'foo@bar.com'
      invite.to.must_equal 'foo@bar.com'
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Presence::MUCUser.new
      invite = muc_user.invite
      invite.from.must_equal nil
      invite.from = 'foo@bar.com'
      invite.from.must_equal 'foo@bar.com'
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Presence::MUCUser.new
      invite = muc_user.invite
      invite.reason.must_equal ''
      invite.reason = 'Please join'
      invite.reason.must_equal 'Please join'
    end
  end

  describe "with a decline element" do
    it "should be an #invite_decline?" do
      muc_user = Blather::XMPPNode.import(parse_stanza(muc_decline_xml).root)
      muc_user.invite_decline?.must_equal true
    end

    it "should know the decline attributes properly" do
      muc_user = Blather::XMPPNode.import(parse_stanza(muc_decline_xml).root)
      decline = muc_user.decline
      decline.to.must_equal 'crone1@shakespeare.lit'
      decline.from.must_equal 'hecate@shakespeare.lit'
      decline.reason.must_equal "Sorry, I'm too busy right now."
    end

    it "must be able to set the to jid" do
      muc_user = Blather::Stanza::Presence::MUCUser.new
      decline = muc_user.decline
      decline.to.must_equal nil
      decline.to = 'foo@bar.com'
      decline.to.must_equal 'foo@bar.com'
    end

    it "must be able to set the from jid" do
      muc_user = Blather::Stanza::Presence::MUCUser.new
      decline = muc_user.decline
      decline.from.must_equal nil
      decline.from = 'foo@bar.com'
      decline.from.must_equal 'foo@bar.com'
    end

    it "must be able to set the reason" do
      muc_user = Blather::Stanza::Presence::MUCUser.new
      decline = muc_user.decline
      decline.reason.must_equal ''
      decline.reason = 'Please join'
      decline.reason.must_equal 'Please join'
    end
  end
end
