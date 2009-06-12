require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])
require 'blather/client/client'

describe Blather::Client do
  before do
    @client = Blather::Client.new
  end

  it 'provides a JID accessor' do
    @client.must_respond_to :jid
    @client.jid.must_be_nil

    jid = 'me@me.com/test'
    @client.must_respond_to :jid=
    @client.jid = jid
    @client.jid.must_be_kind_of Blather::JID
    @client.jid.must_equal Blather::JID.new(jid)
  end

  it 'provides a reader for the roster' do
    @client.must_respond_to :roster
    @client.roster.must_be_kind_of Blather::Roster
  end

  it 'provides a status reader' do
    @client.must_respond_to :status
    @client.status = :away
    @client.status.must_equal :away
  end

  it 'can be setup' do
    @client.must_respond_to :setup
    @client.setup('me@me.com', 'pass').must_equal @client
  end

  it 'knows if it has been setup' do
    @client.must_respond_to :setup?
    @client.setup?.must_equal false
    @client.setup 'me@me.com', 'pass'
    @client.setup?.must_equal true
  end

  it 'cannot be run before being setup' do
    lambda { @client.run }.must_raise RuntimeError
  end

  it 'starts up a Component connection when setup without a node' do
    setup = 'pubsub.jabber.local', 'secret'
    @client.setup *setup
    Blather::Stream::Component.expects(:start).with @client, *setup
    @client.run
  end

  it 'starts up a Client connection when setup with a node' do
    setup = 'test@jabber.local', 'secret'
    @client.setup *setup
    Blather::Stream::Client.expects(:start).with @client, *setup
    @client.run
  end

  it 'writes to the connection the closes when #close is called' do
    stream = mock()
    stream.expects(:close_connection_after_writing)
    Blather::Stream::Component.stubs(:start).returns stream
    @client.setup('me.com', 'secret').run
    @client.close
  end

  it 'shuts down EM when #unbind is called if it is running' do
    EM.expects(:reactor_running?).returns true
    EM.expects(:stop)
    @client.unbind
  end

  it 'does nothing when #unbind is called and EM is not running' do
    EM.expects(:reactor_running?).returns false
    EM.expects(:stop).never
    @client.unbind
  end

  it 'can register a temporary handler based on stanza ID' do
    stanza = Blather::Stanza::Iq.new
    response = mock()
    response.expects(:call)
    @client.register_tmp_handler(stanza.id) { |_| response.call }
    @client.receive_data stanza
  end

  it 'removes a tmp handler as soon as it is used' do
    stanza = Blather::Stanza::Iq.new
    response = mock()
    response.expects(:call)
    @client.register_tmp_handler(stanza.id) { |_| response.call }
    @client.receive_data stanza
    @client.receive_data stanza
  end

  it 'will create a handler then write the stanza' do
    stanza = Blather::Stanza::Iq.new
    response = mock()
    response.expects(:call)
    @client.expects(:write).with do |s|
      @client.receive_data stanza
      s.must_equal stanza
    end
    @client.write_with_handler(stanza) { |_| response.call }
  end

  it 'can register a handler' do
    stanza = Blather::Stanza::Iq.new
    response = mock()
    response.expects(:call).times(2)
    @client.register_handler(:iq) { |_| response.call }
    @client.receive_data stanza
    @client.receive_data stanza
  end

  it 'allows for breaking out of handlers' do
    stanza = Blather::Stanza::Iq.new
    response = mock(:iq => nil)
    @client.register_handler(:iq) do |_|
      response.iq
      throw :halt
      response.fail
    end
    @client.receive_data stanza
  end

  it 'allows for passing to the next handler of the same type' do
    stanza = Blather::Stanza::Iq.new
    response = mock(:iq1 => nil, :iq2 => nil)
    @client.register_handler(:iq) do |_|
      response.iq1
      throw :pass
      response.fail
    end
    @client.register_handler(:iq) do |_|
      response.iq2
    end
    @client.receive_data stanza
  end

  it 'allows for passing to the next handler in the heirarchy' do
    stanza = Blather::Stanza::Iq::Query.new
    response = mock(:query => nil, :iq => nil)
    @client.register_handler(:query) do |_|
      response.query
      throw :pass
      response.fail
    end
    @client.register_handler(:iq) { |_| response.iq }
    @client.receive_data stanza
  end
end

describe 'Blather::Client#write' do
  before do
    @client = Blather::Client.new
  end

  it 'writes to the stream' do
    stanza = Blather::Stanza::Iq.new
    stream = mock()
    stream.expects(:send).with stanza
    Blather::Stream::Client.expects(:start).returns stream
    @client.setup('me@me.com', 'me').run
    @client.write stanza
  end
end

describe 'Blather::Client#status=' do
  before do
    @client = Blather::Client.new
  end

  it 'updates the state when not sending to a JID' do
    @client.status.wont_equal :away
    @client.status = :away, 'message'
    @client.status.must_equal :away
  end

  it 'does not update the state when sending to a JID' do
    @client.status.wont_equal :away
    @client.status = :away, 'message', 'me@me.com'
    @client.status.wont_equal :away
  end

  it 'writes the new status to the stream' do
    Blather::Stanza::Presence::Status.stubs(:next_id).returns 0
    status = [:away, 'message']
    @client.expects(:write).with do |s|
      s.must_be_kind_of Blather::Stanza::Presence::Status
      s.to_s.must_equal Blather::Stanza::Presence::Status.new(*status).to_s
    end
    @client.status = status
  end
end

describe 'Blather::Client default handlers' do
  before do
    @client = Blather::Client.new
  end

  it 're-raises errors' do
    err = Blather::BlatherError.new
    lambda { @client.receive_data err }.must_raise Blather::BlatherError
  end

  it 'responds to iq:get with a "service-unavailable" error' do
    get = Blather::Stanza::Iq.new :get
    err = Blather::StanzaError.new(get, 'service-unavailable', :cancel).to_node
    @client.expects(:write).with err
    @client.receive_data get
  end

  it 'responds to iq:get with a "service-unavailable" error' do
    get = Blather::Stanza::Iq.new :get
    err = Blather::StanzaError.new(get, 'service-unavailable', :cancel).to_node
    @client.expects(:write).with { |n| n.to_s.must_equal err.to_s }
    @client.receive_data get
  end

  it 'responds to iq:set with a "service-unavailable" error' do
    get = Blather::Stanza::Iq.new :set
    err = Blather::StanzaError.new(get, 'service-unavailable', :cancel).to_node
    @client.expects(:write).with { |n| n.to_s.must_equal err.to_s }
    @client.receive_data get
  end

  it 'handles status changes by updating the roster if the status is from a JID in the roster' do
    jid = 'friend@jabber.local'
    status = Blather::Stanza::Presence::Status.new :away
    status.stubs(:from).returns jid
    roster_item = mock()
    roster_item.expects(:status=).with status
    @client.stubs(:roster).returns({status.from => roster_item})
    @client.receive_data status
  end

  it 'lets status stanzas fall through to other handlers' do
    jid = 'friend@jabber.local'
    status = Blather::Stanza::Presence::Status.new :away
    status.stubs(:from).returns jid
    roster_item = mock()
    roster_item.expects(:status=).with status
    @client.stubs(:roster).returns({status.from => roster_item})

    response = mock()
    response.expects(:call).with jid
    @client.register_handler(:status) { |s| response.call s.from.to_s }
    @client.receive_data status
  end

  it 'handles an incoming roster node by processing it through the roster' do
    roster = Blather::Stanza::Iq::Roster.new
    client_roster = mock()
    client_roster.expects(:process).with roster
    @client.stubs(:roster).returns client_roster
    @client.receive_data roster
  end

  it 'handles an incoming roster node by processing it through the roster' do
    roster = Blather::Stanza::Iq::Roster.new
    client_roster = mock()
    client_roster.expects(:process).with roster
    @client.stubs(:roster).returns client_roster

    response = mock()
    response.expects(:call)
    @client.register_handler(:roster) { |_| response.call }
    @client.receive_data roster
  end
end

describe 'Blather::Client with a Component stream' do
  before do
    class MockComponent < Blather::Stream::Component; def initialize(); end; end
    @client = Blather::Client.new 
    Blather::Stream::Component.stubs(:start).returns MockComponent.new('')
    @client.setup('me.com', 'secret').run
  end

  it 'calls the ready handler when sent post_init' do
    ready = mock()
    ready.expects(:call)
    @client.register_handler(:ready) { ready.call }
    @client.post_init
  end
end

describe 'Blather::Client with a Client stream' do
  before do
    class MockClientStream < Blather::Stream::Client; def initialize(); end; end
    @stream = MockClientStream.new('')
    @client = Blather::Client.new 
    Blather::Stream::Client.stubs(:start).returns @stream
    @client.setup('me@me.com', 'secret').run
  end

  it 'sends a request for the roster when post_init is called' do
    @stream.expects(:send).with { |stanza| stanza.must_be_kind_of Blather::Stanza::Iq::Roster }
    @client.post_init
  end

  it 'calls the ready handler after post_init and roster is received' do
    result_roster = Blather::Stanza::Iq::Roster.new :result
    @stream.stubs(:send).with { |s| result_roster.id = s.id; @client.receive_data result_roster; true }

    ready = mock()
    ready.expects(:call)
    @client.register_handler(:ready) { ready.call }
    @client.post_init
  end
end

describe 'Blather::Client guards' do
  before do
    @client = Blather::Client.new
    @stanza = Blather::Stanza::Iq.new
    @response = mock()
  end

  it 'can be a symbol' do
    @response.expects :call
    @client.register_handler(:iq, :chat?) { |_| @response.call }

    @stanza.expects(:chat?).returns true
    @client.receive_data @stanza

    @stanza.expects(:chat?).returns false
    @client.receive_data @stanza
  end

  it 'can be a hash with string match' do
    @response.expects :call
    @client.register_handler(:iq, :body => 'exit') { |_| @response.call }

    @stanza.expects(:body).returns 'exit'
    @client.receive_data @stanza

    @stanza.expects(:body).returns 'not-exit'
    @client.receive_data @stanza
  end

  it 'can be a hash with a value' do
    @response.expects :call
    @client.register_handler(:iq, :number => 0) { |_| @response.call }

    @stanza.expects(:number).returns 0
    @client.receive_data @stanza

    @stanza.expects(:number).returns 1
    @client.receive_data @stanza
  end

  it 'can be a hash with a regexp' do
    @response.expects :call
    @client.register_handler(:iq, :body => /exit/) { |_| @response.call }

    @stanza.expects(:body).returns 'more than just exit, but exit still'
    @client.receive_data @stanza

    @stanza.expects(:body).returns 'keyword not found'
    @client.receive_data @stanza
  end

  it 'can be a hash with an array' do
    @response.expects(:call).times(2)
    @client.register_handler(:iq, :type => [:result, :error]) { |_| @response.call }

    stanza = Blather::Stanza::Iq.new
    stanza.expects(:type).at_least_once.returns :result
    @client.receive_data stanza

    stanza = Blather::Stanza::Iq.new
    stanza.expects(:type).at_least_once.returns :error
    @client.receive_data stanza

    stanza = Blather::Stanza::Iq.new
    stanza.expects(:type).at_least_once.returns :get
    @client.receive_data stanza
  end

  it 'chained are treated like andand (short circuited)' do
    @response.expects :call
    @client.register_handler(:iq, :type => :get, :body => 'test') { |_| @response.call }

    stanza = Blather::Stanza::Iq.new
    stanza.expects(:type).at_least_once.returns :get
    stanza.expects(:body).returns 'test'
    @client.receive_data stanza

    stanza = Blather::Stanza::Iq.new
    stanza.expects(:type).at_least_once.returns :set
    stanza.expects(:body).never
    @client.receive_data stanza
  end

  it 'within an Array are treated as oror (short circuited)' do
    @response.expects(:call).times 2
    @client.register_handler(:iq, [{:type => :get}, {:body => 'test'}]) { |_| @response.call }

    stanza = Blather::Stanza::Iq.new
    stanza.expects(:type).at_least_once.returns :set
    stanza.expects(:body).returns 'test'
    @client.receive_data stanza

    stanza = Blather::Stanza::Iq.new
    stanza.stubs(:type).at_least_once.returns :get
    stanza.expects(:body).never
    @client.receive_data stanza
  end

  it 'can be a lambda' do
    @response.expects :call
    @client.register_handler(:iq, lambda { |s| s.number % 3 == 0 }) { |_| @response.call }

    @stanza.expects(:number).at_least_once.returns 3
    @client.receive_data @stanza

    @stanza.expects(:number).at_least_once.returns 2
    @client.receive_data @stanza
  end

  it 'can be an xpath and will send the result to the handler' do
    @response.expects(:call).with do |stanza, xpath|
      xpath.must_be_instance_of Nokogiri::XML::NodeSet
      xpath.wont_be_empty
      stanza.must_equal @stanza
    end
    @client.register_handler(:iq, "/iq[@id='#{@stanza.id}']") { |stanza, xpath| @response.call stanza, xpath }
    @client.receive_data @stanza
  end

  it 'raises an error when a bad guard is tried' do
    lambda { @client.register_handler(:iq, 0) {} }.must_raise RuntimeError
  end
end
