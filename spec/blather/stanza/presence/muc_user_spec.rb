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

describe 'Blather::Stanza::Presence::MUCUser' do
  it 'must be importable' do
    muc_user = Blather::XMPPNode.parse(muc_user_xml)
    expect(muc_user).to be_kind_of Blather::Stanza::Presence::MUCUser::InstanceMethods
    expect(muc_user.affiliation).to eq(:none)
    expect(muc_user.jid).to eq('hag66@shakespeare.lit/pda')
    expect(muc_user.role).to eq(:participant)
    expect(muc_user.status_codes).to eq([100, 110])
    expect(muc_user.password).to eq('foobar')
  end

  it 'ensures a form node is present on create' do
    c = Blather::Stanza::Presence::MUCUser.new
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns)).not_to be_empty
  end

  it 'ensures a form node exists when calling #muc' do
    c = Blather::Stanza::Presence::MUCUser.new
    c.remove_children :x
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns)).to be_empty

    expect(c.muc_user).not_to be_nil
    expect(c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns)).not_to be_empty
  end

  it "must be able to set the affiliation" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    expect(muc_user.affiliation).to eq(nil)
    muc_user.affiliation = :none
    expect(muc_user.affiliation).to eq(:none)
  end

  it "must be able to set the role" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    expect(muc_user.role).to eq(nil)
    muc_user.role = :participant
    expect(muc_user.role).to eq(:participant)
  end

  it "must be able to set the jid" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    expect(muc_user.jid).to eq(nil)
    muc_user.jid = 'foo@bar.com'
    expect(muc_user.jid).to eq('foo@bar.com')
  end

  it "must be able to set the status codes" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    expect(muc_user.status_codes).to eq([])
    muc_user.status_codes = [100, 110]
    expect(muc_user.status_codes).to eq([100, 110])
    muc_user.status_codes = [500]
    expect(muc_user.status_codes).to eq([500])
  end

  it "must be able to set the password" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    expect(muc_user.password).to eq(nil)
    muc_user.password = 'barbaz'
    expect(muc_user.password).to eq('barbaz')
    muc_user.password = 'hello_world'
    expect(muc_user.password).to eq('hello_world')
  end
end
