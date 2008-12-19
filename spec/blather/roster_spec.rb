require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe 'Blather::Roster' do
  before do
    @stream = mock()
    @stream.stubs(:send_data)

    @stanza = mock()
    items = []; 4.times { |n| items << JID.new("n@d/#{n}r") }
    @stanza.stubs(:items).returns(items)

    @roster = Roster.new(@stream, @stanza)
  end

  it 'initializes with items' do
    @roster.items.map { |_,i| i.jid.to_s }.must_equal(@stanza.items.map { |i| i.stripped.to_s }.uniq)
  end

  it 'processes @stanzas with remove requests' do
    s = @roster['n@d/0r']
    s.subscription = :remove
    proc { @roster.process(s.to_stanza) }.must_change('@roster.items', :length, :by => -1)
  end

  it 'processes @stanzas with add requests' do
    s = Stanza::Iq::Roster::RosterItem.new('a@b/c').to_stanza
    proc { @roster.process(s) }.must_change('@roster.items', :length, :by => 1)
  end

  it 'allows a jid to be pushed' do
    jid = 'a@b/c'
    proc { @roster.push(jid) }.must_change('@roster.items', :length, :by => 1)
    @roster[jid].wont_be_nil
  end

  it 'allows an item to be pushed' do
    jid = 'a@b/c'
    item = RosterItem.new(JID.new(jid))
    proc { @roster.push(item) }.must_change('@roster.items', :length, :by => 1)
    @roster[jid].wont_be_nil
  end

  it 'sends a @roster addition over the wire' do
    stream = mock()
    stream.expects(:send_data)
    roster = Roster.new stream, @stanza
    roster.push('a@b/c')
  end

  it 'removes a JID' do
    proc { @roster.delete 'n@d' }.must_change('@roster.items', :length, :by => -1)
  end

  it 'sends a @roster removal over the wire' do
    stream = mock(:send_data => nil)
    roster = Roster.new stream, @stanza
    roster.delete('a@b/c')
  end

  it 'returns an item through []' do
    item = @roster['n@d']
    item.must_be_kind_of RosterItem
    item.jid.must_equal JID.new('n@d')
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
end
