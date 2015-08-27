require 'spec_helper'

def roster_xml
<<-XML
<iq to='juliet@example.com/balcony' type='result' id='roster_1'>
  <query xmlns='jabber:iq:roster' ver='3bb607aa4fa0bc9e'>
    <item jid='romeo@example.net'
          name='Romeo'
          subscription='both'>
      <group>Friends</group>
    </item>
    <item jid='mercutio@example.org'
          name='Mercutio'
          subscription='from'>
      <group>Friends</group>
    </item>
    <item jid='benvolio@example.org'
          name='Benvolio'
          subscription='both'>
      <group>Friends</group>
    </item>
  </query>
</iq>
XML
end

describe Blather::Stanza::Iq::Roster do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:query, 'jabber:iq:roster').should == Blather::Stanza::Iq::Roster
  end

  it 'ensures newly inherited items are RosterItem objects' do
    n = parse_stanza roster_xml
    r = Blather::Stanza::Iq::Roster.new.inherit n.root
    r.items.map { |i| i.class }.uniq.should == [Blather::Stanza::Iq::Roster::RosterItem]
  end

  it 'can be created with #import' do
    Blather::XMPPNode.parse(roster_xml).should be_instance_of Blather::Stanza::Iq::Roster
  end

  it 'retrieves version' do
    n = parse_stanza roster_xml
    r = Blather::Stanza::Iq::Roster.new.inherit n.root
    expect(r.version).to eq '3bb607aa4fa0bc9e'
  end
end

describe Blather::Stanza::Iq::Roster::RosterItem do
  it 'can be initialized with just a Blather::JID' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new 'n@d/r'
    i.jid.should == Blather::JID.new('n@d/r').stripped
  end

  it 'can be initialized with a name' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new nil, 'foobar'
    i.name.should == 'foobar'
  end

  it 'can be initialized with a subscription' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new nil, nil, :both
    i.subscription.should == :both
  end

  it 'can be initialized with ask (subscription sub-type)' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new nil, nil, nil, :subscribe
    i.ask.should == :subscribe
  end

  it 'can be initailized with a hash' do
    control = { :jid          => 'j@d/r',
                :name         => 'name',
                :subscription => :both,
                :ask          => :subscribe }
    i = Blather::Stanza::Iq::Roster::RosterItem.new control
    i.jid.should == Blather::JID.new(control[:jid]).stripped
    i.name.should == control[:name]
    i.subscription.should == control[:subscription]
    i.ask.should == control[:ask]
  end

  it 'inherits a node when initialized with one' do
    n = Blather::XMPPNode.new 'item'
    n[:jid] = 'n@d/r'
    n[:subscription] = 'both'

    i = Blather::Stanza::Iq::Roster::RosterItem.new n
    i.jid.should == Blather::JID.new('n@d/r')
    i.subscription.should == :both
  end

  it 'has a #groups helper that gives an array of groups' do
    n = parse_stanza "<item jid='romeo@example.net' subscription='both'><group>foo</group><group>bar</group><group>baz</group></item>"
    i = Blather::Stanza::Iq::Roster::RosterItem.new n.root
    i.should respond_to :groups
    i.groups.sort.should == %w[bar baz foo]
  end

  it 'has a helper to set the groups' do
    n = parse_stanza "<item jid='romeo@example.net' subscription='both'><group>foo</group><group>bar</group><group>baz</group></item>"
    i = Blather::Stanza::Iq::Roster::RosterItem.new n.root
    i.should respond_to :groups=
    i.groups.sort.should == %w[bar baz foo]
    i.groups = %w[a b c]
    i.groups.sort.should == %w[a b c]
  end

  it 'can be easily converted into a proper stanza' do
    xml = "<item jid='romeo@example.net' subscription='both'><group>foo</group><group>bar</group><group>baz</group></item>"
    n = parse_stanza xml
    i = Blather::Stanza::Iq::Roster::RosterItem.new n.root
    i.should respond_to :to_stanza
    s = i.to_stanza
    s.should be_kind_of Blather::Stanza::Iq::Roster
    s.items.first.jid.should == Blather::JID.new('romeo@example.net')
    s.items.first.groups.sort.should == %w[bar baz foo]
  end

  it 'has an "attr_accessor" for jid' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    i.should respond_to :jid
    i.jid.should be_nil
    i.should respond_to :jid=
    i.jid = 'n@d/r'
    i.jid.should == Blather::JID.new('n@d/r').stripped
  end

  it 'has a name attribute' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    i.name = 'name'
    i.name.should == 'name'
  end

  it 'has a subscription attribute' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    i.subscription = :both
    i.subscription.should == :both
  end

  it 'has an ask attribute' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    i.ask = :subscribe
    i.ask.should == :subscribe
  end
end
