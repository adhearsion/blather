require File.expand_path "../../spec_helper", __FILE__

describe Blather::JID do
  it 'does nothing if creaded from Blather::JID' do
    jid = Blather::JID.new 'n@d/r'
    Blather::JID.new(jid).object_id.must_equal jid.object_id
  end

  it 'creates a new Blather::JID from (n,d,r)' do
    jid = Blather::JID.new('n', 'd', 'r')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
    jid.resource.must_equal 'r'
  end

  it 'creates a new Blather::JID from (n,d)' do
    jid = Blather::JID.new('n', 'd')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
  end

  it 'creates a new Blather::JID from (n@d)' do
    jid = Blather::JID.new('n@d')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
  end

  it 'creates a new Blather::JID from (n@d/r)' do
    jid = Blather::JID.new('n@d/r')
    jid.node.must_equal 'n'
    jid.domain.must_equal 'd'
    jid.resource.must_equal 'r'
  end

  it 'requires at least a node' do
    proc { Blather::JID.new }.must_raise ::ArgumentError
  end

  it 'ensures length of node is no more than 1023 characters' do
    proc { Blather::JID.new('n'*1024) }.must_raise Blather::ArgumentError
  end

  it 'ensures length of domain is no more than 1023 characters' do
    proc { Blather::JID.new('n', 'd'*1024) }.must_raise Blather::ArgumentError
  end

  it 'ensures length of resource is no more than 1023 characters' do
    proc { Blather::JID.new('n', 'd', 'r'*1024) }.must_raise Blather::ArgumentError
  end

  it 'compares Blather::JIDs' do
    (Blather::JID.new('a@b/c') <=> Blather::JID.new('d@e/f')).must_equal -1
    (Blather::JID.new('a@b/c') <=> Blather::JID.new('a@b/c')).must_equal 0
    (Blather::JID.new('d@e/f') <=> Blather::JID.new('a@b/c')).must_equal 1
  end

  it 'checks for equality' do
    (Blather::JID.new('n@d/r') == Blather::JID.new('n@d/r')).must_equal true
    Blather::JID.new('n@d/r').eql?(Blather::JID.new('n@d/r')).must_equal true
  end

  it 'will strip' do
    jid = Blather::JID.new('n@d/r')
    jid.stripped.must_equal Blather::JID.new('n@d')
    jid.must_equal Blather::JID.new('n@d/r')
  end

  it 'will strip itself' do
    jid = Blather::JID.new('n@d/r')
    jid.strip!
    jid.must_equal Blather::JID.new('n@d')
  end

  it 'has a string representation' do
    Blather::JID.new('n@d/r').to_s.must_equal 'n@d/r'
    Blather::JID.new('n', 'd', 'r').to_s.must_equal 'n@d/r'
    Blather::JID.new('n', 'd').to_s.must_equal 'n@d'
  end

  it 'provides a #stripped? helper' do
    jid = Blather::JID.new 'a@b/c'
    jid.must_respond_to :stripped?
    jid.stripped?.wont_equal true
    jid.strip!
    jid.stripped?.must_equal true
  end
end
