require 'spec_helper'

describe Blather::Roster do
  before do
    @stream = mock()
    @stream.stubs(:write)

    @stanza = mock()
    items = 4.times.map { |n| Blather::Stanza::Iq::Roster::RosterItem.new(jid: "n@d/#{n}r") }
    @stanza.stubs(:items).returns(items)
    @stanza.stubs(:version).returns('24d091d0dcfab1b3')

    @roster = Blather::Roster.new(@stream, @stanza)
  end

  it 'initializes with items' do
    expect(@roster.items.map { |_,i| i.jid.to_s }).to eq(@stanza.items.map { |i| i.jid.stripped.to_s }.uniq)
  end

  it 'processes @stanzas with remove requests' do
    s = @roster['n@d/0r']
    s.subscription = :remove
    expect { @roster.process(s.to_stanza) }.to change(@roster, :length).by -1
  end

  it 'processes @stanzas with add requests' do
    s = Blather::Stanza::Iq::Roster::RosterItem.new('a@b/c').to_stanza
    expect { @roster.process(s) }.to change(@roster, :length).by 1
  end

  it 'allows a jid to be pushed' do
    jid = 'a@b/c'
    expect { @roster.push(jid) }.to change(@roster, :length).by 1
    expect(@roster[jid]).not_to be_nil
  end

  it 'allows an item to be pushed' do
    jid = 'a@b/c'
    item = Blather::RosterItem.new(Blather::JID.new(jid))
    expect { @roster.push(item) }.to change(@roster, :length).by 1
    expect(@roster[jid]).not_to be_nil
  end

  it 'aliases #<< to #push and returns self to allow for chaining' do
    jid = 'a@b/c'
    item = Blather::RosterItem.new(Blather::JID.new(jid))
    jid2 = 'd@e/f'
    item2 = Blather::RosterItem.new(Blather::JID.new(jid2))
    expect { @roster << item << item2 }.to change(@roster, :length).by 2
    expect(@roster[jid]).not_to be_nil
    expect(@roster[jid2]).not_to be_nil
  end

  it 'sends a @roster addition over the wire' do
    client = mock(:write => nil)
    roster = Blather::Roster.new client, @stanza
    roster.push('a@b/c')
  end

  it 'removes a Blather::JID' do
    expect { @roster.delete 'n@d' }.to change(@roster, :length).by -1
  end

  it 'sends a @roster removal over the wire' do
    client = mock(:write => nil)
    roster = Blather::Roster.new client, @stanza
    roster.delete('a@b/c')
  end

  it 'returns an item through []' do
    item = @roster['n@d']
    expect(item).to be_kind_of Blather::RosterItem
    expect(item.jid).to eq(Blather::JID.new('n@d'))
  end

  it 'responds to #each' do
    expect(@roster).to respond_to :each
  end

  it 'cycles through all the items using #each' do
    expect(@roster.map { |i| i }.sort).to eq(@roster.items.values.sort)
  end

  it 'yields RosterItems from #each' do
    @roster.map { |i| expect(i).to be_kind_of Blather::RosterItem }
  end

  it 'returns a duplicate of items through #items' do
    items = @roster.items
    items.delete 'n@d'
    expect(items).not_to equal @roster.items
  end

  it 'will group roster items' do
    @roster.delete 'n@d'
    item1 = Blather::RosterItem.new("n1@d")
    item1.groups = ['group1', 'group2']
    item2 = Blather::RosterItem.new("n2@d")
    item2.groups = ['group1', 'group3']
    @roster << item1 << item2

    expect(@roster.grouped).to eq({
      'group1' => [item1, item2],
      'group2' => [item1],
      'group3' => [item2]
    })
  end

  it 'has a version' do
    expect(@roster.version).to eq @stanza.version
  end
end
