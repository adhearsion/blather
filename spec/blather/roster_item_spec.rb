require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe Blather::RosterItem do
  it 'can be initialized with Blather::JID' do
    jid = Blather::JID.new(jid)
    i = Blather::RosterItem.new jid
    i.jid.must_equal jid
  end

  it 'can be initialized with an Iq::RosterItem' do
    jid = 'n@d/r'
    i = Blather::RosterItem.new Blather::Stanza::Iq::Roster::RosterItem.new(jid)
    i.jid.must_equal Blather::JID.new(jid).stripped
  end

  it 'can be initialized with a string' do
    jid = 'n@d/r'
    i = Blather::RosterItem.new jid
    i.jid.must_equal Blather::JID.new(jid).stripped
  end

  it 'returns the same object when intialized with a Blather::RosterItem' do
    control = Blather::RosterItem.new 'n@d/r'
    Blather::RosterItem.new(control).must_be_same_as control
  end

  it 'has a Blather::JID setter that strips the Blather::JID' do
    jid = Blather::JID.new('n@d/r')
    i = Blather::RosterItem.new nil
    i.jid = jid
    i.jid.must_equal jid.stripped
  end

  it 'has a subscription setter that forces a symbol' do
    i = Blather::RosterItem.new nil
    i.subscription = 'remove'
    i.subscription.must_equal :remove
  end

  it 'forces the type of subscription' do
    proc { Blather::RosterItem.new(nil).subscription = 'foo' }.must_raise Blather::ArgumentError
  end

  it 'returns :none if the subscription field is blank' do
    Blather::RosterItem.new(nil).subscription.must_equal :none
  end

  it 'ensure #ask is a symbol' do
    i = Blather::RosterItem.new(nil)
    i.ask = 'subscribe'
    i.ask.must_equal :subscribe
  end

  it 'forces #ask to be :subscribe or nothing at all' do
    proc { Blather::RosterItem.new(nil).ask = 'foo' }.must_raise Blather::ArgumentError
  end

  it 'generates a stanza with #to_stanza' do
    jid = Blather::JID.new('n@d/r')
    i = Blather::RosterItem.new jid
    s = i.to_stanza
    s.must_be_kind_of Blather::Stanza::Iq::Roster
    s.items.first.jid.must_equal jid.stripped
  end

  it 'returns status based on priority' do
    setup_item_with_presences
    @i.status.must_equal @p2
  end

  it 'returns status based on resource' do
    setup_item_with_presences
    @i.status('a').must_equal @p
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

    @i.status = @p
    @i.status = @p2
  end

  it 'initializes groups to [nil] if the item is not part of a group' do
    i = Blather::RosterItem.new 'n@d'
    i.groups.must_equal [nil]
  end
end
