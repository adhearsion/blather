require 'spec_helper'

describe Blather::JID do
  it 'does nothing if creaded from Blather::JID' do
    jid = Blather::JID.new 'n@d/r'
    Blather::JID.new(jid).object_id.should == jid.object_id
  end

  it 'creates a new Blather::JID from (n,d,r)' do
    jid = Blather::JID.new('n', 'd', 'r')
    jid.node.should == 'n'
    jid.domain.should == 'd'
    jid.resource.should == 'r'
  end

  it 'creates a new Blather::JID from (n,d)' do
    jid = Blather::JID.new('n', 'd')
    jid.node.should == 'n'
    jid.domain.should == 'd'
  end

  it 'creates a new Blather::JID from (n@d)' do
    jid = Blather::JID.new('n@d')
    jid.node.should == 'n'
    jid.domain.should == 'd'
  end

  it 'creates a new Blather::JID from (n@d/r)' do
    jid = Blather::JID.new('n@d/r')
    jid.node.should == 'n'
    jid.domain.should == 'd'
    jid.resource.should == 'r'
  end

  it 'requires at least a node' do
    proc { Blather::JID.new }.should raise_error ::ArgumentError
  end

  it 'ensures length of node is no more than 1023 characters' do
    proc { Blather::JID.new('n'*1024) }.should raise_error Blather::ArgumentError
  end

  it 'ensures length of domain is no more than 1023 characters' do
    proc { Blather::JID.new('n', 'd'*1024) }.should raise_error Blather::ArgumentError
  end

  it 'ensures length of resource is no more than 1023 characters' do
    proc { Blather::JID.new('n', 'd', 'r'*1024) }.should raise_error Blather::ArgumentError
  end

  it 'compares Blather::JIDs' do
    (Blather::JID.new('a@b/c') <=> Blather::JID.new('d@e/f')).should == -1
    (Blather::JID.new('a@b/c') <=> Blather::JID.new('a@b/c')).should == 0
    (Blather::JID.new('d@e/f') <=> Blather::JID.new('a@b/c')).should == 1
  end

  it 'checks for equality' do
    (Blather::JID.new('n@d/r') == Blather::JID.new('n@d/r')).should == true
    Blather::JID.new('n@d/r').eql?(Blather::JID.new('n@d/r')).should == true
  end

  it 'will strip' do
    jid = Blather::JID.new('n@d/r')
    jid.stripped.should == Blather::JID.new('n@d')
    jid.should == Blather::JID.new('n@d/r')
  end

  it 'will strip itself' do
    jid = Blather::JID.new('n@d/r')
    jid.strip!
    jid.should == Blather::JID.new('n@d')
  end

  it 'has a string representation' do
    Blather::JID.new('n@d/r').to_s.should == 'n@d/r'
    Blather::JID.new('n', 'd', 'r').to_s.should == 'n@d/r'
    Blather::JID.new('n', 'd').to_s.should == 'n@d'
  end

  it 'provides a #stripped? helper' do
    jid = Blather::JID.new 'a@b/c'
    jid.should respond_to :stripped?
    jid.stripped?.should_not equal true
    jid.strip!
    jid.stripped?.should == true
  end
end
