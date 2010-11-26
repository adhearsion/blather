require File.expand_path "../../../spec_helper", __FILE__
require 'blather/client/dsl'

describe Blather::DSL do
  before do
    @client = mock()
    @dsl = Class.new { include Blather::DSL }.new
    Blather::Client.stubs(:new).returns(@client)
  end

  it 'wraps the setup' do
    args = ['jid', 'pass', 'host', 0000]
    @client.expects(:setup).with *args
    @dsl.setup *args
  end

  it 'allows host to be nil in setup' do
    args = ['jid', 'pass']
    @client.expects(:setup).with *(args + [nil, nil])
    @dsl.setup *args
  end

  it 'allows port to be nil in setup' do
    args = ['jid', 'pass', 'host']
    @client.expects(:setup).with *(args + [nil])
    @dsl.setup *args
  end

  it 'stops when shutdown is called' do
    @client.expects(:close)
    @dsl.shutdown
  end

  it 'can throw a halt' do
    catch(:halt) { @dsl.halt }
  end

  it 'can throw a pass' do
    catch(:pass) { @dsl.pass }
  end

  it 'can setup before filters' do
    guards = [:chat?, {:body => 'exit'}]
    @client.expects(:register_filter).with :before, nil, *guards
    @dsl.before nil, *guards
  end

  it 'can setup after filters' do
    guards = [:chat?, {:body => 'exit'}]
    @client.expects(:register_filter).with :after, nil, *guards
    @dsl.after nil, *guards
  end

  it 'sets up handlers' do
    type = :message
    guards = [:chat?, {:body => 'exit'}]
    @client.expects(:register_handler).with type, *guards
    @dsl.handle type, *guards
  end

  it 'provides a helper for ready state' do
    @client.expects(:register_handler).with :ready
    @dsl.when_ready
  end

  it 'provides a helper for disconnected' do
    @client.expects(:register_handler).with :disconnected
    @dsl.disconnected
  end

  it 'sets the initial status' do
    state = :away
    msg = 'do not disturb'
    @client.expects(:status=).with [state, msg]
    @dsl.set_status state, msg
  end

  it 'provides a roster accessor' do
    @client.expects :roster
    @dsl.my_roster
  end

  it 'provides a << style writer that provides chaining' do
    stanza = Blather::Stanza::Iq.new
    @client.expects(:write).with stanza
    (@dsl << stanza).must_equal @dsl
  end

  it 'provides a writer' do
    stanza = Blather::Stanza::Iq.new
    @client.expects(:write).with stanza
    @dsl.write_to_stream stanza
  end

  it 'provides a "say" helper' do
    to, msg = 'me@me.com', 'hello!'
    Blather::Stanza::Message.stubs(:next_id).returns 0
    @client.expects(:write).with { |n| n.to_s.must_equal Blather::Stanza::Message.new(to, msg).to_s }
    @dsl.say to, msg
  end

  it 'provides a JID accessor' do
    @client.expects :jid
    @dsl.jid
  end

  it 'provides a disco helper for items' do
    what, who, where = :items, 'me@me.com', 'my/node'
    Blather::Stanza::Disco::DiscoItems.stubs(:next_id).returns 0
    @client.expects(:register_tmp_handler).with '0'
    expected_stanza = Blather::Stanza::Disco::DiscoItems.new
    expected_stanza.to = who
    expected_stanza.node = where
    @client.expects(:write).with { |n| n.to_s.must_equal expected_stanza.to_s }
    @dsl.discover what, who, where
  end

  it 'provides a disco helper for info' do
    what, who, where = :info, 'me@me.com', 'my/node'
    Blather::Stanza::Disco::DiscoInfo.stubs(:next_id).returns 0
    @client.expects(:register_tmp_handler).with '0'
    expected_stanza = Blather::Stanza::Disco::DiscoInfo.new
    expected_stanza.to = who
    expected_stanza.node = where
    @client.expects(:write).with { |n| n.to_s.must_equal expected_stanza.to_s }
    @dsl.discover what, who, where
  end

  Blather::Stanza.handler_list.each do |handler_method|
    it "provides a helper method for #{handler_method}" do
      guards = [:chat?, {:body => 'exit'}]
      @client.expects(:register_handler).with handler_method, *guards
      @dsl.__send__(handler_method, *guards)
    end
  end

  it 'has a pubsub helper set to the jid domain' do
    jid = Blather::JID.new('jid@domain/resource')
    @client.stubs(:jid).returns jid
    @dsl.pubsub.must_be_instance_of Blather::DSL::PubSub
    @dsl.pubsub.host.must_equal jid.domain
  end
end
