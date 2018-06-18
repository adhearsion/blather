require 'spec_helper'

describe Blather::Stanza::Presence::Status do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:status, nil)).to eq(Blather::Stanza::Presence::Status)
  end

  it 'must be importable as unavailable' do
    expect(Blather::XMPPNode.parse('<presence type="unavailable"/>')).to be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
  end

  it 'must be importable as nil' do
    expect(Blather::XMPPNode.parse('<presence/>')).to be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
  end

  it 'must be importable with show, status and priority children' do
    n = Blather::XMPPNode.parse <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <show>chat</show>
        <status>Talk to me!</status>
        <priority>10</priority>
      </presence>
    XML
    expect(n).to be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
    expect(n.state).to eq(:chat)
    expect(n.message).to eq('Talk to me!')
    expect(n.priority).to eq(10)
  end

  it 'can set state on creation' do
    status = Blather::Stanza::Presence::Status.new :away
    expect(status.state).to eq(:away)
  end

  it 'can set a message on creation' do
    status = Blather::Stanza::Presence::Status.new nil, 'Say hello!'
    expect(status.message).to eq('Say hello!')
  end

  it 'ensures type is nil or :unavailable' do
    status = Blather::Stanza::Presence::Status.new
    expect { status.type = :invalid_type_name }.to raise_error(Blather::ArgumentError)

    [nil, :unavailable].each do |valid_type|
      status.type = valid_type
      expect(status.type).to eq(valid_type)
    end
  end

  it 'ensures state is one of Presence::Status::VALID_STATES' do
    status = Blather::Stanza::Presence::Status.new
    expect { status.state = :invalid_type_name }.to raise_error(Blather::ArgumentError)

    Blather::Stanza::Presence::Status::VALID_STATES.each do |valid_state|
      status.state = valid_state
      expect(status.state).to eq(valid_state)
    end
  end

  it 'returns :available if state is nil' do
    expect(Blather::Stanza::Presence::Status.new.state).to eq(:available)
  end

  it 'returns :available if <show/> is blank' do
    status = Blather::XMPPNode.parse(<<-NODE)
      <presence><show/></presence>
    NODE
    expect(status.state).to eq(:available)
  end

  it 'returns :unavailable if type is :unavailable' do
    status = Blather::Stanza::Presence::Status.new
    status.type = :unavailable
    expect(status.state).to eq(:unavailable)
  end

  it 'ensures priority is not greater than 127' do
    expect { Blather::Stanza::Presence::Status.new.priority = 128 }.to raise_error(Blather::ArgumentError)
  end

  it 'ensures priority is not less than -128' do
    expect { Blather::Stanza::Presence::Status.new.priority = -129 }.to raise_error(Blather::ArgumentError)
  end

  it 'has "attr_accessor" for priority' do
    status = Blather::Stanza::Presence::Status.new
    expect(status.priority).to eq(0)

    status.priority = 10
    expect(status.children.detect { |n| n.element_name == 'priority' }).not_to be_nil
    expect(status.priority).to eq(10)
  end

  it 'has "attr_accessor" for message' do
    status = Blather::Stanza::Presence::Status.new
    expect(status.message).to be_nil

    status.message = 'new message'
    expect(status.children.detect { |n| n.element_name == 'status' }).not_to be_nil
    expect(status.message).to eq('new message')
  end

  it 'must be comparable by priority' do
    jid = Blather::JID.new 'a@b/c'

    status1 = Blather::Stanza::Presence::Status.new
    status1.from = jid

    status2 = Blather::Stanza::Presence::Status.new
    status2.from = jid

    status1.priority = 1
    status2.priority = -1
    expect(status1 <=> status2).to eq(1)
    expect(status2 <=> status1).to eq(-1)

    status2.priority = 1
    expect(status1 <=> status2).to eq(0)
  end

  it 'must should sort by status if priorities are equal' do
    jid = Blather::JID.new 'a@b/c'

    status1 = Blather::Stanza::Presence::Status.new :away
    status1.from = jid

    status2 = Blather::Stanza::Presence::Status.new :available
    status2.from = jid

    status1.priority = status2.priority = 1
    expect(status1 <=> status2).to eq(-1)
    expect(status2 <=> status1).to eq(1)
  end

  it 'raises an argument error if compared to a status with a different Blather::JID' do
    status1 = Blather::Stanza::Presence::Status.new
    status1.from = 'a@b/c'

    status2 = Blather::Stanza::Presence::Status.new
    status2.from = 'd@e/f'

    expect { status1 <=> status2 }.to raise_error(Blather::ArgumentError)
  end

  ([:available] + Blather::Stanza::Presence::Status::VALID_STATES).each do |valid_state|
    it "provides a helper (#{valid_state}?) for state #{valid_state}" do
      expect(Blather::Stanza::Presence::Status.new).to respond_to :"#{valid_state}?"
    end

    it "returns true on call to (#{valid_state}?) if state == #{valid_state}" do
      method = "#{valid_state}?".to_sym
      stat = Blather::Stanza::Presence::Status.new
      stat.state = valid_state
      expect(stat).to respond_to method
      expect(stat.__send__(method)).to eq(true)
    end
  end
end
