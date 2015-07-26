require 'spec_helper'

describe Blather::Stanza::Presence::Status do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:status, nil).should == Blather::Stanza::Presence::Status
  end

  it 'must be importable as unavailable' do
    Blather::XMPPNode.parse('<presence type="unavailable"/>').should be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
  end

  it 'must be importable as nil' do
    Blather::XMPPNode.parse('<presence/>').should be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
  end

  it 'must be importable with show, status and priority children' do
    n = Blather::XMPPNode.parse <<-XML
      <presence from='bard@shakespeare.lit/globe'>
        <show>chat</show>
        <status>Talk to me!</status>
        <priority>10</priority>
      </presence>
    XML
    n.should be_kind_of Blather::Stanza::Presence::Status::InstanceMethods
    n.state.should == :chat
    n.message.should == 'Talk to me!'
    n.priority.should == 10
  end

  it 'can set state on creation' do
    status = Blather::Stanza::Presence::Status.new :away
    status.state.should == :away
  end

  it 'can set a message on creation' do
    status = Blather::Stanza::Presence::Status.new nil, 'Say hello!'
    status.message.should == 'Say hello!'
  end

  it 'ensures type is nil or :unavailable' do
    status = Blather::Stanza::Presence::Status.new
    lambda { status.type = :invalid_type_name }.should raise_error(Blather::ArgumentError)

    [nil, :unavailable].each do |valid_type|
      status.type = valid_type
      status.type.should == valid_type
    end
  end

  it 'ensures state is one of Presence::Status::VALID_STATES' do
    status = Blather::Stanza::Presence::Status.new
    lambda { status.state = :invalid_type_name }.should raise_error(Blather::ArgumentError)

    Blather::Stanza::Presence::Status::VALID_STATES.each do |valid_state|
      status.state = valid_state
      status.state.should == valid_state
    end
  end

  it 'returns :available if state is nil' do
    Blather::Stanza::Presence::Status.new.state.should == :available
  end

  it 'returns :available if <show/> is blank' do
    status = Blather::XMPPNode.parse(<<-NODE)
      <presence><show/></presence>
    NODE
    status.state.should == :available
  end

  it 'returns :unavailable if type is :unavailable' do
    status = Blather::Stanza::Presence::Status.new
    status.type = :unavailable
    status.state.should == :unavailable
  end

  it 'ensures priority is not greater than 127' do
    lambda { Blather::Stanza::Presence::Status.new.priority = 128 }.should raise_error(Blather::ArgumentError)
  end

  it 'ensures priority is not less than -128' do
    lambda { Blather::Stanza::Presence::Status.new.priority = -129 }.should raise_error(Blather::ArgumentError)
  end

  it 'has "attr_accessor" for priority' do
    status = Blather::Stanza::Presence::Status.new
    status.priority.should == 0

    status.priority = 10
    status.children.detect { |n| n.element_name == 'priority' }.should_not be_nil
    status.priority.should == 10
  end

  it 'has "attr_accessor" for message' do
    status = Blather::Stanza::Presence::Status.new
    status.message.should be_nil

    status.message = 'new message'
    status.children.detect { |n| n.element_name == 'status' }.should_not be_nil
    status.message.should == 'new message'
  end

  it 'must be comparable by priority' do
    jid = Blather::JID.new 'a@b/c'

    status1 = Blather::Stanza::Presence::Status.new
    status1.from = jid

    status2 = Blather::Stanza::Presence::Status.new
    status2.from = jid

    status1.priority = 1
    status2.priority = -1
    (status1 <=> status2).should == 1
    (status2 <=> status1).should == -1

    status2.priority = 1
    (status1 <=> status2).should == 0
  end

  it 'must should sort by status if priorities are equal' do
    jid = Blather::JID.new 'a@b/c'

    status1 = Blather::Stanza::Presence::Status.new :away
    status1.from = jid

    status2 = Blather::Stanza::Presence::Status.new :available
    status2.from = jid

    status1.priority = status2.priority = 1
    (status1 <=> status2).should == -1
    (status2 <=> status1).should == 1
  end

  it 'raises an argument error if compared to a status with a different Blather::JID' do
    status1 = Blather::Stanza::Presence::Status.new
    status1.from = 'a@b/c'

    status2 = Blather::Stanza::Presence::Status.new
    status2.from = 'd@e/f'

    lambda { status1 <=> status2 }.should raise_error(Blather::ArgumentError)
  end

  ([:available] + Blather::Stanza::Presence::Status::VALID_STATES).each do |valid_state|
    it "provides a helper (#{valid_state}?) for state #{valid_state}" do
      Blather::Stanza::Presence::Status.new.should respond_to :"#{valid_state}?"
    end

    it "returns true on call to (#{valid_state}?) if state == #{valid_state}" do
      method = "#{valid_state}?".to_sym
      stat = Blather::Stanza::Presence::Status.new
      stat.state = valid_state
      stat.should respond_to method
      stat.__send__(method).should == true
    end
  end
end
