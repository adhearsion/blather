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
      </x>
    </presence>
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
end
