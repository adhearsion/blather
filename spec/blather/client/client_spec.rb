require 'spec_helper'
require 'blather/client/client'

describe Blather::Client do
  let(:jid)     { Blather::JID.new 'n@d/r' }
  let(:stream)  { mock 'Stream' }

  before do
    stream.stubs :send
  end

  it 'provides a Blather::JID reader' do
    subject.post_init stream, jid
    expect(subject).to respond_to :jid
    expect(subject.jid).to eq(jid)
  end

  it 'provides a reader for the roster' do
    expect(subject).to respond_to :roster
    expect(subject.roster).to be_kind_of Blather::Roster
  end

  it 'provides a status reader' do
    subject.post_init stream, jid
    expect(subject).to respond_to :status
    subject.status = :away
    expect(subject.status).to eq(:away)
  end

  it 'should have a caps handler' do
    expect(subject).to respond_to :caps
    expect(subject.caps).to be_kind_of Blather::Stanza::Capabilities
  end

  describe '#setup' do
    it 'can be setup' do
      expect(subject).to respond_to :setup
      expect(subject.setup('me@me.com', 'pass')).to eq(subject)
    end

    it 'knows if it has been setup' do
      expect(subject).to respond_to :setup?
      expect(subject).not_to be_setup
      subject.setup 'me@me.com', 'pass'
      expect(subject).to be_setup
    end

    it 'cannot be run before being setup' do
      expect { subject.run }.to raise_error RuntimeError
    end

    it 'starts up a Component connection when setup without a node' do
      setup = 'pubsub.jabber.local', 'secret'
      subject.setup *setup
      Blather::Stream::Component.expects(:start).with subject, *setup + [nil, nil, nil, nil, {}]
      subject.run
    end

    it 'starts up a Client connection when setup with a node' do
      setup = 'test@jabber.local', 'secret'
      subject.setup *setup
      Blather::Stream::Client.expects(:start).with subject, *setup + [nil, nil, nil, nil, {}]
      subject.run
    end

    context "setting queue size" do
      let(:jid)        { 'test@jabber.local' }
      let(:password)   { 'secret' }
      let(:queue_size) { 3 }

      subject { Blather::Client.setup(jid, password, nil, nil, nil, nil, :workqueue_count => queue_size) }

      it 'sets the queue size on the client' do
        expect(subject.queue_size).to eq(queue_size)
      end

      describe 'receiving data' do
        let(:stanza) { Blather::Stanza::Iq.new }

        context 'when the queue size is 0' do
          let(:queue_size) { 0 }

          it "has no handler queue" do
            expect(subject.handler_queue).to be_nil
          end

          it 'handles the data immediately' do
            subject.expects(:handle_data).with(stanza)
            subject.receive_data stanza
          end
        end

        context 'when the queue size is non-zero' do
          let(:queue_size) { 4 }

          it 'enqueues the data on the handler queue' do
            subject.handler_queue.expects(:<<).with(stanza)
            subject.receive_data stanza
          end
        end
      end
    end
  end

  it 'knows if it is disconnected' do
    expect(subject).to respond_to :connected?
    expect(subject).not_to be_connected
  end

  it 'knows if it is connected' do
    stream.expects(:stopped?).returns false
    subject.setup 'me.com', 'secret'
    subject.post_init stream, Blather::JID.new('me.com')
    expect(subject).to be_connected
  end

  describe 'if it has been setup but not connected yet' do
    it 'should consider itself disconnected' do
      subject.setup 'me.com', 'secret'
      expect(subject).not_to be_connected
    end
  end

  describe '#close' do
    before do
      EM.stubs(:next_tick).yields
      subject.setup 'me.com', 'secret'
    end

    context "without a setup stream" do
      it "does not close the connection" do
        stream.expects(:close_connection_after_writing).never
        subject.close
      end
    end

    context "when a stream is setup" do
      let(:stream_stopped) { false }
      before do
        subject.post_init stream, Blather::JID.new('me.com')
        stream.stubs(:stopped? => stream_stopped)
      end

      context "when the stream is stopped" do
        let(:stream_stopped) { true }

        it "does not close the connection, since it's already closed" do
          stream.expects(:close_connection_after_writing).never
        end
      end

      it 'writes to the connection the closes when #close is called' do
        stream.expects(:close_connection_after_writing)
        subject.close
      end

      it 'shuts down the workqueue' do
        stream.stubs(:close_connection_after_writing)
        subject.handler_queue.expects(:shutdown)
        subject.close
      end

      it 'forces the work queue to be re-created when referenced' do
        stream.stubs(:close_connection_after_writing)
        subject.close

        fake_queue = stub('GirlFriday::WorkQueue')
        GirlFriday::WorkQueue.expects(:new)
        .with(:handle_stanza, :size => subject.queue_size)
          .returns(fake_queue)

        expect(subject.handler_queue).to eq(fake_queue)
      end
    end
  end

  it 'shuts down EM when #unbind is called if it is running' do
    EM.expects(:reactor_running?).returns true
    EM.expects(:stop)
    subject.unbind
  end

  it 'does nothing when #unbind is called and EM is not running' do
    EM.expects(:reactor_running?).returns false
    EM.expects(:stop).never
    subject.unbind
  end

  it 'calls the :disconnected handler with #unbind is called' do
    EM.expects(:reactor_running?).returns false
    disconnected = mock
    disconnected.expects(:call)
    subject.register_handler(:disconnected) { disconnected.call }
    subject.unbind
  end

  it 'does not call EM.stop on #unbind if a handler returns positive' do
    EM.expects(:reactor_running?).never
    EM.expects(:stop).never
    disconnected = mock
    disconnected.expects(:call).returns true
    subject.register_handler(:disconnected) { disconnected.call }
    subject.unbind
  end

  it 'calls EM.stop on #unbind if a handler returns negative' do
    EM.expects(:reactor_running?).returns true
    EM.expects(:stop)
    disconnected = mock
    disconnected.expects(:call).returns false
    subject.register_handler(:disconnected) { disconnected.call }
    subject.unbind
  end

  it 'can register a temporary handler based on stanza ID' do
    stanza = Blather::Stanza::Iq.new
    response = mock
    response.expects(:call)
    subject.register_tmp_handler(stanza.id) { |_| response.call }
    subject.receive_data stanza
  end

  it 'removes a tmp handler as soon as it is used' do
    stanza = Blather::Stanza::Iq.new
    response = mock
    response.expects(:call)
    subject.register_tmp_handler(stanza.id) { |_| response.call }
    subject.receive_data stanza
    subject.receive_data stanza
  end

  it 'will create a handler then write the stanza' do
    stanza = Blather::Stanza::Iq.new
    response = mock
    response.expects(:call)
    subject.expects(:write).with do |s|
      subject.receive_data stanza
      expect(s).to eq(stanza)
    end
    subject.write_with_handler(stanza) { |_| response.call }
  end

  it 'can register a handler' do
    stanza = Blather::Stanza::Iq.new
    response = mock
    response.expects(:call).times(2)
    subject.register_handler(:iq) { |_| response.call }
    subject.receive_data stanza
    subject.receive_data stanza
  end

  it 'allows for breaking out of handlers' do
    stanza = Blather::Stanza::Iq.new
    response = mock(:iq => nil)
    subject.register_handler(:iq) do |_|
      response.iq
      throw :halt
      response.fail
    end
    subject.receive_data stanza
  end

  it 'allows for passing to the next handler of the same type' do
    stanza = Blather::Stanza::Iq.new
    response = mock(:iq1 => nil, :iq2 => nil)
    subject.register_handler(:iq) do |_|
      response.iq1
      throw :pass
      response.fail
    end
    subject.register_handler(:iq) do |_|
      response.iq2
    end
    subject.receive_data stanza
  end

  it 'allows for passing to the next handler in the hierarchy' do
    stanza = Blather::Stanza::Iq::Query.new
    response = mock(:query => nil, :iq => nil)
    subject.register_handler(:query) do |_|
      response.query
      throw :pass
      response.fail
    end
    subject.register_handler(:iq) { |_| response.iq }
    subject.receive_data stanza
  end

  it 'can clear handlers' do
    stanza = Blather::Stanza::Message.new
    stanza.expects(:chat?).returns true

    response = mock
    response.expects(:call).once

    subject.register_handler(:message, :chat?) { |_| response.call }
    subject.receive_data stanza

    subject.clear_handlers :message, :chat?
    subject.receive_data stanza
  end

  describe '#write' do
    it 'writes to the stream' do
      stanza = Blather::Stanza::Iq.new
      stream.expects(:send).with stanza
      subject.setup 'me@me.com', 'me'
      subject.post_init stream, Blather::JID.new('me.com')
      subject.write stanza
    end
  end

  describe '#status=' do
    before do
      subject.post_init stream, Blather::JID.new('n@d/r')
    end

    it 'updates the state when not sending to a Blather::JID' do
      stream.stubs(:write)
      expect(subject.status).not_to equal :away
      subject.status = :away, 'message'
      expect(subject.status).to eq(:away)
    end

    it 'does not update the state when sending to a Blather::JID' do
      stream.stubs(:write)
      expect(subject.status).not_to equal :away
      subject.status = :away, 'message', 'me@me.com'
      expect(subject.status).not_to equal :away
    end

    it 'writes the new status to the stream' do
      Blather::Stanza::Presence::Status.stubs(:next_id).returns 0
      status = [:away, 'message']
      stream.expects(:send).with do |s|
        expect(s).to be_kind_of Blather::Stanza::Presence::Status
        expect(s.to_s).to eq(Blather::Stanza::Presence::Status.new(*status).to_s)
      end
      subject.status = status
    end
  end

  describe 'default handlers' do
    it 're-raises errors' do
      err = Blather::BlatherError.new
      expect { subject.receive_data err }.to raise_error Blather::BlatherError
    end

    # it 'responds to iq:get with a "service-unavailable" error' do
    #   get = Blather::Stanza::Iq.new :get
    #   err = Blather::StanzaError.new(get, 'service-unavailable', :cancel).to_node
    #   subject.expects(:write).with err
    #   subject.receive_data get
    # end

    # it 'responds to iq:get with a "service-unavailable" error' do
    #   get = Blather::Stanza::Iq.new :get
    #   err = Blather::StanzaError.new(get, 'service-unavailable', :cancel).to_node
    #   subject.expects(:write).with { |n| n.to_s.should == err.to_s }
    #   subject.receive_data get
    # end

    # it 'responds to iq:set with a "service-unavailable" error' do
    #   get = Blather::Stanza::Iq.new :set
    #   err = Blather::StanzaError.new(get, 'service-unavailable', :cancel).to_node
    #   subject.expects(:write).with { |n| n.to_s.should == err.to_s }
    #   subject.receive_data get
    # end

    it 'responds to s2c pings with a pong' do
      ping = Blather::Stanza::Iq::Ping.new :get
      pong = ping.reply
      subject.expects(:write).with { |n| expect(n.to_s).to eq(pong.to_s) }
      subject.receive_data ping
    end

    it 'handles status changes by updating the roster if the status is from a Blather::JID in the roster' do
      jid = 'friend@jabber.local'
      status = Blather::Stanza::Presence::Status.new :away
      status.stubs(:from).returns jid
      roster_item = mock
      roster_item.expects(:status=).with status
      subject.stubs(:roster).returns({status.from => roster_item})
      subject.receive_data status
    end

    it 'lets status stanzas fall through to other handlers' do
      jid = 'friend@jabber.local'
      status = Blather::Stanza::Presence::Status.new :away
      status.stubs(:from).returns jid
      roster_item = mock
      roster_item.expects(:status=).with status
      subject.stubs(:roster).returns({status.from => roster_item})

      response = mock
      response.expects(:call).with jid
      subject.register_handler(:status) { |s| response.call s.from.to_s }
      subject.receive_data status
    end

    it 'handles an incoming roster node by processing it through the roster' do
      roster = Blather::Stanza::Iq::Roster.new
      client_roster = mock
      client_roster.expects(:process).with roster
      subject.stubs(:roster).returns client_roster
      subject.receive_data roster
    end

    it 'handles an incoming roster node by processing it through the roster' do
      roster = Blather::Stanza::Iq::Roster.new
      client_roster = mock
      client_roster.expects(:process).with roster
      subject.stubs(:roster).returns client_roster

      response = mock
      response.expects(:call)
      subject.register_handler(:roster) { |_| response.call }
      subject.receive_data roster
    end
  end

  describe 'with a Component stream' do
    before do
      class MockComponent < Blather::Stream::Component; def initialize(); end; end
      stream = MockComponent.new('')
      stream.stubs(:send_data)
      subject.setup 'me.com', 'secret'
    end

    it 'calls the ready handler when sent post_init' do
      ready = mock
      ready.expects(:call)
      subject.register_handler(:ready) { ready.call }
      subject.post_init stream
    end
  end

  describe 'with a Client stream' do
    before do
      class MockClientStream < Blather::Stream::Client; def initialize(); end; end
      stream = MockClientStream.new('')
      Blather::Stream::Client.stubs(:start).returns stream
      subject.setup('me@me.com', 'secret').run
    end

    it 'sends a request for the roster when post_init is called' do
      stream.expects(:send).with { |stanza| expect(stanza).to be_kind_of Blather::Stanza::Iq::Roster }
      subject.post_init stream, Blather::JID.new('n@d/r')
    end

    it 'calls the ready handler after post_init and roster is received' do
      result_roster = Blather::Stanza::Iq::Roster.new :result
      stream.stubs(:send).with do |s|
        result_roster.id = s.id
        subject.receive_data result_roster
        true
      end

      ready = mock
      ready.expects(:call)
      subject.register_handler(:ready) { ready.call }
      subject.post_init stream, Blather::JID.new('n@d/r')
    end

    it 'gracefully handles service unavailability upon requesting the roster' do
      result_roster = Blather::Stanza::Iq.parse <<-XML
        <iq type="error" to="n@d/r">
          <error type="cancel">
            <service-unavailable xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>
          </error>
        </iq>
      XML

      stream.stubs(:send).with do |s|
        result_roster.id = s.id
        subject.receive_data result_roster
        true
      end

      ready = mock
      ready.expects(:call)
      subject.register_handler(:ready) { ready.call }
      subject.post_init stream, Blather::JID.new('n@d/r')
    end
  end

  describe 'filters' do
    it 'raises an error when an invalid filter type is registered' do
      expect { subject.register_filter(:invalid) {} }.to raise_error RuntimeError
    end

    it 'can be guarded' do
      stanza = Blather::Stanza::Iq.new
      ready = mock
      ready.expects(:call).once
      subject.register_filter(:before, :iq, :id => stanza.id) { |_| ready.call }
      subject.register_filter(:before, :iq, :id => 'not-id') { |_| ready.call }
      subject.receive_data stanza
    end

    it 'can pass to the next handler' do
      stanza = Blather::Stanza::Iq.new
      ready = mock
      ready.expects(:call).once
      subject.register_filter(:before) { |_| throw :pass; ready.call }
      subject.register_filter(:before) { |_| ready.call }
      subject.receive_data stanza
    end

    it 'runs them in order' do
      stanza = Blather::Stanza::Iq.new
      count = 0
      subject.register_filter(:before) { |_| expect(count).to eq(0); count = 1 }
      subject.register_filter(:before) { |_| expect(count).to eq(1); count = 2 }
      subject.register_handler(:iq) { |_| expect(count).to eq(2); count = 3 }
      subject.register_filter(:after) { |_| expect(count).to eq(3); count = 4 }
      subject.register_filter(:after) { |_| expect(count).to eq(4) }
      subject.receive_data stanza
    end

    it 'can modify the stanza' do
      stanza = Blather::Stanza::Iq.new
      stanza.from = 'from@test.local'
      new_jid = 'before@filter.local'
      ready = mock
      ready.expects(:call).with new_jid
      subject.register_filter(:before) { |s| s.from = new_jid }
      subject.register_handler(:iq) { |s| ready.call s.from.to_s }
      subject.receive_data stanza
    end

    it 'can halt the handler chain' do
      stanza = Blather::Stanza::Iq.new
      ready = mock
      ready.expects(:call).never
      subject.register_filter(:before) { |_| throw :halt }
      subject.register_handler(:iq) { |_| ready.call }
      subject.receive_data stanza
    end

    it 'can be specific to a handler' do
      stanza = Blather::Stanza::Iq.new
      ready = mock
      ready.expects(:call).once
      subject.register_filter(:before, :iq) { |_| ready.call }
      subject.register_filter(:before, :message) { |_| ready.call }
      subject.receive_data stanza
    end
  end

  describe 'guards' do
    let(:stanza)    { Blather::Stanza::Iq.new }
    let(:response)  { mock }

    it 'can be a symbol' do
      response.expects :call
      subject.register_handler(:iq, :chat?) { |_| response.call }

      stanza.expects(:chat?).returns true
      subject.receive_data stanza

      stanza.expects(:chat?).returns false
      subject.receive_data stanza
    end

    it 'can be a hash with string match' do
      response.expects :call
      subject.register_handler(:iq, :body => 'exit') { |_| response.call }

      stanza.expects(:body).returns 'exit'
      subject.receive_data stanza

      stanza.expects(:body).returns 'not-exit'
      subject.receive_data stanza
    end

    it 'can be a hash with a value' do
      response.expects :call
      subject.register_handler(:iq, :number => 0) { |_| response.call }

      stanza.expects(:number).returns 0
      subject.receive_data stanza

      stanza.expects(:number).returns 1
      subject.receive_data stanza
    end

    it 'can be a hash with a regexp' do
      response.expects :call
      subject.register_handler(:iq, :body => /exit/) { |_| response.call }

      stanza.expects(:body).returns 'more than just exit, but exit still'
      subject.receive_data stanza

      stanza.expects(:body).returns 'keyword not found'
      subject.receive_data stanza

      stanza.expects(:body).returns nil
      subject.receive_data stanza
    end

    it 'can be a hash with an array' do
      response.expects(:call).times(2)
      subject.register_handler(:iq, :type => [:result, :error]) { |_| response.call }

      stanza = Blather::Stanza::Iq.new
      stanza.expects(:type).at_least_once.returns :result
      subject.receive_data stanza

      stanza = Blather::Stanza::Iq.new
      stanza.expects(:type).at_least_once.returns :error
      subject.receive_data stanza

      stanza = Blather::Stanza::Iq.new
      stanza.expects(:type).at_least_once.returns :get
      subject.receive_data stanza
    end

    it 'chained are treated like andand (short circuited)' do
      response.expects :call
      subject.register_handler(:iq, :type => :get, :body => 'test') { |_| response.call }

      stanza = Blather::Stanza::Iq.new
      stanza.expects(:type).at_least_once.returns :get
      stanza.expects(:body).returns 'test'
      subject.receive_data stanza

      stanza = Blather::Stanza::Iq.new
      stanza.expects(:type).at_least_once.returns :set
      stanza.expects(:body).never
      subject.receive_data stanza
    end

    it 'within an Array are treated as oror (short circuited)' do
      response.expects(:call).times 2
      subject.register_handler(:iq, [{:type => :get}, {:body => 'test'}]) { |_| response.call }

      stanza = Blather::Stanza::Iq.new
      stanza.expects(:type).at_least_once.returns :set
      stanza.expects(:body).returns 'test'
      subject.receive_data stanza

      stanza = Blather::Stanza::Iq.new
      stanza.stubs(:type).at_least_once.returns :get
      stanza.expects(:body).never
      subject.receive_data stanza
    end

    it 'can be a lambda' do
      response.expects :call
      subject.register_handler(:iq, lambda { |s| s.number % 3 == 0 }) { |_| response.call }

      stanza.expects(:number).at_least_once.returns 3
      subject.receive_data stanza

      stanza.expects(:number).at_least_once.returns 2
      subject.receive_data stanza
    end

    it 'can be an xpath and will send the result to the handler' do
      response.expects(:call).with do |stanza, xpath|
        expect(xpath).to be_instance_of Nokogiri::XML::NodeSet
        expect(xpath).not_to be_empty
        expect(stanza).to eq(stanza)
      end
      subject.register_handler(:iq, "/iq[@id='#{stanza.id}']") { |stanza, xpath| response.call stanza, xpath }
      subject.receive_data stanza
    end

    it 'can be an xpath with namespaces and will send the result to the handler' do
      stanza = Blather::Stanza.parse('<message><foo xmlns="http://bar.com"></message>')
      response.expects(:call).with do |stanza, xpath|
        expect(xpath).to be_instance_of Nokogiri::XML::NodeSet
        expect(xpath).not_to be_empty
        expect(stanza).to eq(stanza)
      end
      subject.register_handler(:message, "/message/bar:foo", :bar => 'http://bar.com') { |stanza, xpath| response.call stanza, xpath }
      subject.receive_data stanza
    end

    it 'raises an error when a bad guard is tried' do
      expect { subject.register_handler(:iq, 0) {} }.to raise_error RuntimeError
    end
  end

  describe '#caps' do
    let(:caps) { subject.caps }

    it 'must be of type result' do
      expect(caps).to respond_to :type
      expect(caps.type).to eq(:result)
    end

    it 'can have a client node set' do
      expect(caps).to respond_to :node=
      caps.node = "somenode"
    end

    it 'provides a client node reader' do
      expect(caps).to respond_to :node
      caps.node = "somenode"
      expect(caps.node).to eq("somenode##{caps.ver}")
    end

    it 'can have identities set' do
      expect(caps).to respond_to :identities=
      caps.identities = [{:name => "name", :type => "type", :category => "cat"}]
    end

    it 'provides an identities reader' do
      expect(caps).to respond_to :identities
      caps.identities = [{:name => "name", :type => "type", :category => "cat"}]
      expect(caps.identities).to eq([Blather::Stanza::Iq::DiscoInfo::Identity.new({:name => "name", :type => "type", :category => "cat"})])
    end

    it 'can have features set' do
      expect(caps).to respond_to :features=
      expect(caps.features.size).to eq(0)
      caps.features = ["feature1"]
      expect(caps.features.size).to eq(1)
      caps.features += [Blather::Stanza::Iq::DiscoInfo::Feature.new("feature2")]
      expect(caps.features.size).to eq(2)
      caps.features = nil
      expect(caps.features.size).to eq(0)
    end

    it 'provides a features reader' do
      expect(caps).to respond_to :features
      caps.features = %w{feature1 feature2}
      expect(caps.features).to eq([Blather::Stanza::Iq::DiscoInfo::Feature.new("feature1"), Blather::Stanza::Iq::DiscoInfo::Feature.new("feature2")])
    end

    it 'provides a client ver reader' do
      expect(caps).to respond_to :ver
      caps.node = 'http://code.google.com/p/exodus'
      caps.identities = [Blather::Stanza::Iq::DiscoInfo::Identity.new({:name => 'Exodus 0.9.1', :type => 'pc', :category => 'client'})]
      caps.features = %w{
                            http://jabber.org/protocol/caps
                            http://jabber.org/protocol/disco#info
                            http://jabber.org/protocol/disco#items
                            http://jabber.org/protocol/muc
                          }
      expect(caps.ver).to eq('QgayPKawpkPSDYmwT/WM94uAlu0=')
      expect(caps.node).to eq("http://code.google.com/p/exodus#QgayPKawpkPSDYmwT/WM94uAlu0=")
    end

    it 'can construct caps presence correctly' do
      expect(caps).to respond_to :c
      caps.node = 'http://code.google.com/p/exodus'
      caps.identities = [Blather::Stanza::Iq::DiscoInfo::Identity.new({:name => 'Exodus 0.9.1', :type => 'pc', :category => 'client'})]
      caps.features = %w{
                            http://jabber.org/protocol/caps
                            http://jabber.org/protocol/disco#info
                            http://jabber.org/protocol/disco#items
                            http://jabber.org/protocol/muc
                          }
      expect(Nokogiri::XML(caps.c.to_xml).to_s).to eq(Nokogiri::XML("<presence><c xmlns=\"http://jabber.org/protocol/caps\" hash=\"sha-1\" node=\"http://code.google.com/p/exodus\" ver=\"QgayPKawpkPSDYmwT/WM94uAlu0=\"/></presence>").to_s)
    end
  end
end
