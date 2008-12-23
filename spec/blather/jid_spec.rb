require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe 'Blather::JID' do
  it 'does nothing if creaded from JID' do
    jid = JID.new 'n@d/r'
    JID.new(jid).object_id.must_equal jid.object_id
  end

  it 'creates a new JID from (n,d,r)' do
    jid = JID.new('n', 'd', 'r')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
    jid.resource.must_equal 'r'
  end

  it 'creates a new JID from (n,d)' do
    jid = JID.new('n', 'd')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
  end

  it 'creates a new JID from (n@d)' do
    jid = JID.new('n@d')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
  end

  it 'creates a new JID from (n@d/r)' do
    jid = JID.new('n@d/r')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
    jid.resource.must_equal 'r'
  end

  it 'requires at least a node' do
    proc { JID.new }.must_raise ArgumentError
  end

  it 'ensures length of node is no more than 1023 characters' do
    proc { JID.new('n'*1024) }.must_raise Blather::ArgumentError
  end

  it 'ensures length of domain is no more than 1023 characters' do
    proc { JID.new('n', 'd'*1024) }.must_raise Blather::ArgumentError
  end

  it 'ensures length of resource is no more than 1023 characters' do
    proc { JID.new('n', 'd', 'r'*1024) }.must_raise Blather::ArgumentError
  end

  it 'compares JIDs' do
    (JID.new('a@b/c') <=> JID.new('d@e/f')).must_equal -1
    (JID.new('a@b/c') <=> JID.new('a@b/c')).must_equal 0
    (JID.new('d@e/f') <=> JID.new('a@b/c')).must_equal 1
  end

  it 'checks for equality' do
    (JID.new('n@d/r') == JID.new('n@d/r')).must_equal true
  end

  it 'will strip' do
    jid = JID.new('n@d/r')
    jid.stripped.must_equal JID.new('n@d')
    jid.must_equal JID.new('n@d/r')
  end

  it 'will strip itself' do
    jid = JID.new('n@d/r')
    jid.strip!
    jid.must_equal JID.new('n@d')
  end

  it 'has a string representation' do
    JID.new('n@d/r').to_s.must_equal 'n@d/r'
    JID.new('n', 'd', 'r').to_s.must_equal 'n@d/r'
    JID.new('n', 'd').to_s.must_equal 'n@d'
  end

  it 'provides a #stripped? helper' do
    jid = JID.new 'a@b/c'
    jid.must_respond_to :stripped?
    jid.stripped?.wont_equal true
    jid.strip!
    jid.stripped?.must_equal true
  end
end
