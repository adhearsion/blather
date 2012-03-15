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
    muc_user.should be_kind_of Blather::Stanza::Presence::MUCUser::InstanceMethods
    muc_user.affiliation.should == :none
    muc_user.jid.should == 'hag66@shakespeare.lit/pda'
    muc_user.role.should == :participant
    muc_user.status_codes.should == [100, 110]
    muc_user.password.should == 'foobar'
  end

  it 'ensures a form node is present on create' do
    c = Blather::Stanza::Presence::MUCUser.new
    c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns).should_not be_empty
  end

  it 'ensures a form node exists when calling #muc' do
    c = Blather::Stanza::Presence::MUCUser.new
    c.remove_children :x
    c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns).should be_empty

    c.muc_user.should_not be_nil
    c.xpath('ns:x', :ns => Blather::Stanza::Presence::MUCUser.registered_ns).should_not be_empty
  end

  it "must be able to set the affiliation" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.affiliation.should == nil
    muc_user.affiliation = :none
    muc_user.affiliation.should == :none
  end

  it "must be able to set the role" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.role.should == nil
    muc_user.role = :participant
    muc_user.role.should == :participant
  end

  it "must be able to set the jid" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.jid.should == nil
    muc_user.jid = 'foo@bar.com'
    muc_user.jid.should == 'foo@bar.com'
  end

  it "must be able to set the status codes" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.status_codes.should == []
    muc_user.status_codes = [100, 110]
    muc_user.status_codes.should == [100, 110]
    muc_user.status_codes = [500]
    muc_user.status_codes.should == [500]
  end

  it "must be able to set the password" do
    muc_user = Blather::Stanza::Presence::MUCUser.new
    muc_user.password.should == nil
    muc_user.password = 'barbaz'
    muc_user.password.should == 'barbaz'
    muc_user.password = 'hello_world'
    muc_user.password.should == 'hello_world'
  end
end
