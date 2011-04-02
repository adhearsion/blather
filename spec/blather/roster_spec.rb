require 'spec_helper'

describe Blather::Roster do
  before do
    @stream = mock()
    @stream.stubs(:write)

    @stanza = mock()
    items = []; 4.times { |n| items << Blather::JID.new("n@d/#{n}r") }
    @stanza.stubs(:items).returns(items)

    @roster = Blather::Roster.new(@stream, @stanza)
  end

  it 'initializes with items' do
    @roster.items.map { |_,i| i.jid.to_s }.must_equal(@stanza.items.map { |i| i.stripped.to_s }.uniq)
  end

  it 'processes @stanzas with remove requests' do
    s = @roster['n@d/0r']
    s.subscription = :remove
    proc { @roster.process(s.to_stanza) }.must_change('@roster.items.length', :by => -1)
  end

  it 'processes @stanzas with add requests' do
    s = Blather::Stanza::Iq::Roster::RosterItem.new('a@b/c').to_stanza
    proc { @roster.process(s) }.must_change('@roster.items.length', :by => 1)
  end

  it 'allows a jid to be pushed' do
    jid = 'a@b/c'
    proc { @roster.push(jid) }.must_change('@roster.items.length', :by => 1)
    @roster[jid].wont_be_nil
  end

  it 'allows an item to be pushed' do
    jid = 'a@b/c'
    item = Blather::RosterItem.new(Blather::JID.new(jid))
    proc { @roster.push(item) }.must_change('@roster.items.length', :by => 1)
    @roster[jid].wont_be_nil
  end

  it 'aliases #<< to #push and returns self to allow for chaining' do
    jid = 'a@b/c'
    item = Blather::RosterItem.new(Blather::JID.new(jid))
    jid2 = 'd@e/f'
    item2 = Blather::RosterItem.new(Blather::JID.new(jid2))
    proc { @roster << item << item2 }.must_change('@roster.items.length', :by => 2)
    @roster[jid].wont_be_nil
    @roster[jid2].wont_be_nil
  end

  it 'sends a @roster addition over the wire' do
    client = mock(:write => nil)
    roster = Blather::Roster.new client, @stanza
    roster.push('a@b/c')
  end

  it 'removes a Blather::JID' do
    proc { @roster.delete 'n@d' }.must_change('@roster.items.length', :by => -1)
  end

  it 'sends a @roster removal over the wire' do
    client = mock(:write => nil)
    roster = Blather::Roster.new client, @stanza
    roster.delete('a@b/c')
  end

  it 'returns an item through []' do
    item = @roster['n@d']
    item.must_be_kind_of Blather::RosterItem
    item.jid.must_equal Blather::JID.new('n@d')
  end

  it 'responds to #each' do
    @roster.must_respond_to :each
  end

  it 'cycles through the items using #each' do
    @roster.map { |i| i }.sort.must_equal(@roster.items.sort)
  end

  it 'returns a duplicate of items through #items' do
    items = @roster.items
    items.delete 'n@d'
    items.wont_equal @roster.items
  end

  it 'will group roster items' do
    @roster.delete 'n@d'
    item1 = Blather::RosterItem.new("n1@d")
    item1.groups = ['group1', 'group2']
    item2 = Blather::RosterItem.new("n2@d")
    item2.groups = ['group1', 'group3']
    @roster << item1 << item2

    @roster.grouped.must_equal({
      'group1' => [item1, item2],
      'group2' => [item1],
      'group3' => [item2]
    })
  end
end
