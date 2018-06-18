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
    expect(Blather::XMPPNode.class_from_registration(:query, 'jabber:iq:roster')).to eq(Blather::Stanza::Iq::Roster)
  end

  it 'ensures newly inherited items are RosterItem objects' do
    n = parse_stanza roster_xml
    r = Blather::Stanza::Iq::Roster.new.inherit n.root
    expect(r.items.map { |i| i.class }.uniq).to eq([Blather::Stanza::Iq::Roster::RosterItem])
  end

  it 'can be created with #import' do
    expect(Blather::XMPPNode.parse(roster_xml)).to be_instance_of Blather::Stanza::Iq::Roster
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
    expect(i.jid).to eq(Blather::JID.new('n@d/r').stripped)
  end

  it 'can be initialized with a name' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new nil, 'foobar'
    expect(i.name).to eq('foobar')
  end

  it 'can be initialized with a subscription' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new nil, nil, :both
    expect(i.subscription).to eq(:both)
  end

  it 'can be initialized with ask (subscription sub-type)' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new nil, nil, nil, :subscribe
    expect(i.ask).to eq(:subscribe)
  end

  it 'can be initailized with a hash' do
    control = { :jid          => 'j@d/r',
                :name         => 'name',
                :subscription => :both,
                :ask          => :subscribe }
    i = Blather::Stanza::Iq::Roster::RosterItem.new control
    expect(i.jid).to eq(Blather::JID.new(control[:jid]).stripped)
    expect(i.name).to eq(control[:name])
    expect(i.subscription).to eq(control[:subscription])
    expect(i.ask).to eq(control[:ask])
  end

  it 'inherits a node when initialized with one' do
    n = Blather::XMPPNode.new 'item'
    n[:jid] = 'n@d/r'
    n[:subscription] = 'both'

    i = Blather::Stanza::Iq::Roster::RosterItem.new n
    expect(i.jid).to eq(Blather::JID.new('n@d/r'))
    expect(i.subscription).to eq(:both)
  end

  it 'has a #groups helper that gives an array of groups' do
    n = parse_stanza "<item jid='romeo@example.net' subscription='both'><group>foo</group><group>bar</group><group>baz</group></item>"
    i = Blather::Stanza::Iq::Roster::RosterItem.new n.root
    expect(i).to respond_to :groups
    expect(i.groups.sort).to eq(%w[bar baz foo])
  end

  it 'has a helper to set the groups' do
    n = parse_stanza "<item jid='romeo@example.net' subscription='both'><group>foo</group><group>bar</group><group>baz</group></item>"
    i = Blather::Stanza::Iq::Roster::RosterItem.new n.root
    expect(i).to respond_to :groups=
    expect(i.groups.sort).to eq(%w[bar baz foo])
    i.groups = %w[a b c]
    expect(i.groups.sort).to eq(%w[a b c])
  end

  it 'can be easily converted into a proper stanza' do
    xml = "<item jid='romeo@example.net' subscription='both'><group>foo</group><group>bar</group><group>baz</group></item>"
    n = parse_stanza xml
    i = Blather::Stanza::Iq::Roster::RosterItem.new n.root
    expect(i).to respond_to :to_stanza
    s = i.to_stanza
    expect(s).to be_kind_of Blather::Stanza::Iq::Roster
    expect(s.items.first.jid).to eq(Blather::JID.new('romeo@example.net'))
    expect(s.items.first.groups.sort).to eq(%w[bar baz foo])
  end

  it 'has an "attr_accessor" for jid' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    expect(i).to respond_to :jid
    expect(i.jid).to be_nil
    expect(i).to respond_to :jid=
    i.jid = 'n@d/r'
    expect(i.jid).to eq(Blather::JID.new('n@d/r').stripped)
  end

  it 'has a name attribute' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    i.name = 'name'
    expect(i.name).to eq('name')
  end

  it 'has a subscription attribute' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    i.subscription = :both
    expect(i.subscription).to eq(:both)
  end

  it 'has an ask attribute' do
    i = Blather::Stanza::Iq::Roster::RosterItem.new
    i.ask = :subscribe
    expect(i.ask).to eq(:subscribe)
  end
end
