require 'spec_helper'

describe Blather::RosterItem do
  it 'can be initialized with Blather::JID' do
    jid = Blather::JID.new(jid)
    i = Blather::RosterItem.new jid
    i.jid.should == jid
  end

  it 'can be initialized with an Iq::RosterItem' do
    jid = 'n@d/r'
    i = Blather::RosterItem.new Blather::Stanza::Iq::Roster::RosterItem.new(jid)
    i.jid.should == Blather::JID.new(jid).stripped
  end

  it 'can be initialized with a string' do
    jid = 'n@d/r'
    i = Blather::RosterItem.new jid
    i.jid.should == Blather::JID.new(jid).stripped
  end

  it 'returns the same object when intialized with a Blather::RosterItem' do
    control = Blather::RosterItem.new 'n@d/r'
    Blather::RosterItem.new(control).should be control
  end

  it 'has a Blather::JID setter that strips the Blather::JID' do
    jid = Blather::JID.new('n@d/r')
    i = Blather::RosterItem.new nil
    i.jid = jid
    i.jid.should == jid.stripped
  end

  it 'has a subscription setter that forces a symbol' do
    i = Blather::RosterItem.new nil
    i.subscription = 'remove'
    i.subscription.should == :remove
  end

  it 'forces the type of subscription' do
    proc { Blather::RosterItem.new(nil).subscription = 'foo' }.should raise_error Blather::ArgumentError
  end

  it 'returns :none if the subscription field is blank' do
    Blather::RosterItem.new(nil).subscription.should == :none
  end

  it 'ensure #ask is a symbol' do
    i = Blather::RosterItem.new(nil)
    i.ask = 'subscribe'
    i.ask.should == :subscribe
  end

  it 'forces #ask to be :subscribe or nothing at all' do
    proc { Blather::RosterItem.new(nil).ask = 'foo' }.should raise_error Blather::ArgumentError
  end

  it 'generates a stanza with #to_stanza' do
    jid = Blather::JID.new('n@d/r')
    i = Blather::RosterItem.new jid
    s = i.to_stanza
    s.should be_kind_of Blather::Stanza::Iq::Roster
    s.items.first.jid.should == jid.stripped
  end

  it 'returns status based on priority' do
    setup_item_with_presences
    @i.status.should == @p3
  end

  it 'returns status based on priority and state' do
    setup_item_with_presences

    @p4 = Blather::Stanza::Presence::Status.new
    @p4.type = :unavailable
    @p4.from = 'n@d/d'
    @p4.priority = 15
    @i.status = @p4

    @i.status.should == @p3
  end

  it 'returns status based on resource' do
    setup_item_with_presences
    @i.status('a').should == @p
  end

  def setup_item_with_presences
    @jid = Blather::JID.new('n@d/r')
    @i = Blather::RosterItem.new @jid

    @p = Blather::Stanza::Presence::Status.new(:away)
    @p.from = 'n@d/a'
    @p.priority = 0

    @p2 = Blather::Stanza::Presence::Status.new(:dnd)
    @p2.from = 'n@d/b'
    @p2.priority = -1

    @p3 = Blather::Stanza::Presence::Status.new(:dnd)
    @p3.from = 'n@d/c'
    @p3.priority = 10

    @i.status = @p
    @i.status = @p2
    @i.status = @p3
  end

  it 'removes old unavailable presences' do
    setup_item_with_presences

    50.times do |i|
      p = Blather::Stanza::Presence::Status.new
      p.type = :unavailable
      p.from = "n@d/#{i}"
      @i.status = p
    end

    @i.statuses.size.should == 4
  end

  it 'initializes groups to [nil] if the item is not part of a group' do
    i = Blather::RosterItem.new 'n@d'
    i.groups.should == [nil]
  end

  it 'can determine equality' do
    item1 = Blather::RosterItem.new 'n@d'
    item2 = Blather::RosterItem.new 'n@d'
    item1.groups = %w[group1 group2]
    item2.groups = %w[group1 group2]
    (item1 == item2).should == true
  end
end
