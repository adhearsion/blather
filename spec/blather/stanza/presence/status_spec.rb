require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

describe 'Blather::Stanza::Presence::Status' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:status, nil).must_equal Stanza::Presence::Status
  end

  it 'can set state on creation' do
    status = Stanza::Presence::Status.new :away
    status.state.must_equal :away
  end

  it 'can set a message on creation' do
    status = Stanza::Presence::Status.new nil, 'Say hello!'
    status.message.must_equal 'Say hello!'
  end

  it 'ensures type is nil or :unavailable' do
    status = Stanza::Presence::Status.new
    lambda { status.type = :invalid_type_name }.must_raise(Blather::ArgumentError)

    [nil, :unavailable].each do |valid_type|
      status.type = valid_type
      status.type.must_equal valid_type
    end
  end

  it 'ensures state is one of Presence::Status::VALID_STATES' do
    status = Stanza::Presence::Status.new
    lambda { status.state = :invalid_type_name }.must_raise(Blather::ArgumentError)

    Stanza::Presence::Status::VALID_STATES.each do |valid_state|
      status.state = valid_state
      status.state.must_equal valid_state
    end
  end

  it 'returns :available if state is nil' do
    Stanza::Presence::Status.new.state.must_equal :available
  end

  it 'returns :unavailable if type is :unavailable' do
    status = Stanza::Presence::Status.new
    status.type = :unavailable
    status.state.must_equal :unavailable
  end

  it 'ensures priority is not greater than 127' do
    lambda { Stanza::Presence::Status.new.priority = 128 }.must_raise(Blather::ArgumentError)
  end

  it 'ensures priority is not less than -128' do
    lambda { Stanza::Presence::Status.new.priority = -129 }.must_raise(Blather::ArgumentError)
  end

  it 'has "attr_accessor" for priority' do
    status = Stanza::Presence::Status.new
    status.priority.must_equal 0

    status.priority = 10
    status.find_first('/presence[priority="10"]').wont_be_nil
    status.priority.must_equal 10
  end

  it 'has "attr_accessor" for message' do
    status = Stanza::Presence::Status.new
    status.message.must_be_nil

    status.message = 'new message'
    status.find_first('/presence[status="new message"]').wont_be_nil
    status.message.must_equal 'new message'
  end

  it 'must be comparable by priority' do
    jid = JID.new 'a@b/c'

    status1 = Stanza::Presence::Status.new
    status1.from = jid

    status2 = Stanza::Presence::Status.new
    status2.from = jid

    status1.priority = 1
    status2.priority = -1
    (status1 <=> status2).must_equal 1
    (status2 <=> status1).must_equal -1

    status2.priority = 1
    (status1 <=> status2).must_equal 0
  end

  it 'raises an argument error if compared to a status with a different JID' do
    status1 = Stanza::Presence::Status.new
    status1.from = 'a@b/c'

    status2 = Stanza::Presence::Status.new
    status2.from = 'd@e/f'

    lambda { status1 <=> status2 }.must_raise(Blather::ArgumentError)
  end
end

