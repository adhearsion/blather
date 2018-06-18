require 'spec_helper'

describe Blather::JID do
  it 'does nothing if creaded from Blather::JID' do
    jid = Blather::JID.new 'n@d/r'
    expect(Blather::JID.new(jid).object_id).to eq(jid.object_id)
  end

  it 'creates a new Blather::JID from (n,d,r)' do
    jid = Blather::JID.new('n', 'd', 'r')
    expect(jid.node).to eq('n')
    expect(jid.domain).to eq('d')
    expect(jid.resource).to eq('r')
  end

  it 'creates a new Blather::JID from (n,d)' do
    jid = Blather::JID.new('n', 'd')
    expect(jid.node).to eq('n')
    expect(jid.domain).to eq('d')
  end

  it 'creates a new Blather::JID from (n@d)' do
    jid = Blather::JID.new('n@d')
    expect(jid.node).to eq('n')
    expect(jid.domain).to eq('d')
  end

  it 'creates a new Blather::JID from (n@d/r)' do
    jid = Blather::JID.new('n@d/r')
    expect(jid.node).to eq('n')
    expect(jid.domain).to eq('d')
    expect(jid.resource).to eq('r')
  end

  it 'requires at least a node' do
    expect { Blather::JID.new }.to raise_error ::ArgumentError
  end

  it 'ensures length of node is no more than 1023 characters' do
    expect { Blather::JID.new('n'*1024) }.to raise_error Blather::ArgumentError
  end

  it 'ensures length of domain is no more than 1023 characters' do
    expect { Blather::JID.new('n', 'd'*1024) }.to raise_error Blather::ArgumentError
  end

  it 'ensures length of resource is no more than 1023 characters' do
    expect { Blather::JID.new('n', 'd', 'r'*1024) }.to raise_error Blather::ArgumentError
  end

  it 'compares Blather::JIDs' do
    expect(Blather::JID.new('a@b/c') <=> Blather::JID.new('d@e/f')).to eq(-1)
    expect(Blather::JID.new('a@b/c') <=> Blather::JID.new('a@b/c')).to eq(0)
    expect(Blather::JID.new('d@e/f') <=> Blather::JID.new('a@b/c')).to eq(1)
  end

  it 'checks for equality' do
    expect(Blather::JID.new('n@d/r') == Blather::JID.new('n@d/r')).to eq(true)
    expect(Blather::JID.new('n@d/r').eql?(Blather::JID.new('n@d/r'))).to eq(true)
  end

  it 'will strip' do
    jid = Blather::JID.new('n@d/r')
    expect(jid.stripped).to eq(Blather::JID.new('n@d'))
    expect(jid).to eq(Blather::JID.new('n@d/r'))
  end

  it 'will strip itself' do
    jid = Blather::JID.new('n@d/r')
    jid.strip!
    expect(jid).to eq(Blather::JID.new('n@d'))
  end

  it 'has a string representation' do
    expect(Blather::JID.new('n@d/r').to_s).to eq('n@d/r')
    expect(Blather::JID.new('n', 'd', 'r').to_s).to eq('n@d/r')
    expect(Blather::JID.new('n', 'd').to_s).to eq('n@d')
  end

  it 'provides a #stripped? helper' do
    jid = Blather::JID.new 'a@b/c'
    expect(jid).to respond_to :stripped?
    expect(jid.stripped?).not_to equal true
    jid.strip!
    expect(jid.stripped?).to eq(true)
  end
end
