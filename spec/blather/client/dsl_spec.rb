require 'spec_helper'
require 'blather/client/dsl'

describe Blather::DSL do
  before do
    @client = Blather::Client.new
    @stream = mock()
    @stream.stubs(:send)
    @client.post_init @stream, Blather::JID.new('n@d/r')
    @dsl = Class.new { include Blather::DSL }.new
    Blather::Client.stubs(:new).returns(@client)
  end

  it 'wraps the setup' do
    args = ['jid', 'pass', 'host', 0000]
    @client.expects(:setup).with *(args + [nil, nil, nil])
    @dsl.setup *args
  end

  it 'allows host to be nil in setup' do
    args = ['jid', 'pass']
    @client.expects(:setup).with *(args + [nil, nil, nil, nil])
    @dsl.setup *args
  end

  it 'allows port to be nil in setup' do
    args = ['jid', 'pass', 'host']
    @client.expects(:setup).with *(args + [nil, nil, nil])
    @dsl.setup *args
  end

  it 'allows certs to be nil in setup' do
    args = ['jid', 'pass', 'host', 'port']
    @client.expects(:setup).with *(args + [nil, nil])
    @dsl.setup *args
  end

  it 'accepts certs in setup' do
    args = ['jid', 'pass', 'host', 'port', 'certs']
    @client.expects(:setup).with *(args + [nil])
    @dsl.setup *args
  end

  it 'accepts connection timeout in setup' do
    args = ['jid', 'pass', 'host', 'port', 'certs', 30]
    @client.expects(:setup).with *args
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

  it 'sets up handler methods' do
    @client.expects(:register_handler).with :presence, :unavailable?
    @dsl.presence :unavailable?
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
    (@dsl << stanza).should == @dsl
  end

  it 'provides a writer' do
    stanza = Blather::Stanza::Iq.new
    @client.expects(:write).with stanza
    @dsl.write_to_stream stanza
  end

  it 'provides a "say" helper' do
    to, msg = 'me@me.com', 'hello!'
    Blather::Stanza::Message.stubs(:next_id).returns 0
    @client.expects(:write).with Blather::Stanza::Message.new(to, msg)
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
    @client.expects(:write).with expected_stanza
    @dsl.discover what, who, where
  end

  it 'provides a disco helper for info' do
    what, who, where = :info, 'me@me.com', 'my/node'
    Blather::Stanza::Disco::DiscoInfo.stubs(:next_id).returns 0
    @client.expects(:register_tmp_handler).with '0'
    expected_stanza = Blather::Stanza::Disco::DiscoInfo.new
    expected_stanza.to = who
    expected_stanza.node = where
    @client.expects(:write).with expected_stanza
    @dsl.discover what, who, where
  end

  it 'provides a caps set helper' do
    @dsl.should respond_to :set_caps
    node = 'http://code.google.com/p/exodus'
    identities = [Blather::Stanza::Iq::DiscoInfo::Identity.new({:name => 'Exodus 0.9.1', :type => 'pc', :category => 'client'})]
    features = %w{
                  http://jabber.org/protocol/caps
                  http://jabber.org/protocol/disco#info
                  http://jabber.org/protocol/disco#items
                  http://jabber.org/protocol/muc
                }
    @dsl.set_caps node, identities, features
    @client.caps.node.should == "#{node}##{@client.caps.ver}"
    @client.caps.identities.should == identities
    @client.caps.features.map{ |f| f.var }.should == features
  end

  it 'provides a caps send helper' do
    @dsl.should respond_to :send_caps
    @client.caps.node = 'http://code.google.com/p/exodus'
    @client.caps.identities = [Blather::Stanza::Iq::DiscoInfo::Identity.new({:name => 'Exodus 0.9.1', :type => 'pc', :category => 'client'})]
    @client.caps.features = %w{
                          http://jabber.org/protocol/caps
                          http://jabber.org/protocol/disco#info
                          http://jabber.org/protocol/disco#items
                          http://jabber.org/protocol/muc
                        }
    expected_stanza = Blather::Stanza.parse(<<-XML)
      <presence>
        <c xmlns="http://jabber.org/protocol/caps" hash="sha-1"
           node="http://code.google.com/p/exodus"
           ver="QgayPKawpkPSDYmwT/WM94uAlu0="
        />
      </presence>
    XML
    @client.expects(:write).with expected_stanza
    @client.expects(:register_handler).with(:disco_info, :type => :get, :node => "http://code.google.com/p/exodus#QgayPKawpkPSDYmwT/WM94uAlu0=")
    @dsl.send_caps
  end

  it 'responds with correct disco stanza after sending caps and receiving query' do
    @client.caps.node = 'http://code.google.com/p/exodus'
    @client.caps.identities = [Blather::Stanza::Iq::DiscoInfo::Identity.new({:name => 'Exodus 0.9.1', :type => 'pc', :category => 'client'})]
    @client.caps.features = %w{
                          http://jabber.org/protocol/caps
                          http://jabber.org/protocol/disco#info
                          http://jabber.org/protocol/disco#items
                          http://jabber.org/protocol/muc
                        }
    stanza = <<-XML
      <iq from='juliet@capulet.lit/chamber'
          id='disco1'
          to='romeo@montague.lit/orchard'
          type='get'>
        <query xmlns='http://jabber.org/protocol/disco#info'
               node='http://code.google.com/p/exodus#QgayPKawpkPSDYmwT/WM94uAlu0='/>
      </iq>
    XML
    @stanza = Blather::Stanza.parse(stanza)

    expected_stanza = Blather::Stanza.parse(<<-XML)
      <iq type="result" id="disco1" to="juliet@capulet.lit/chamber">
        <query xmlns="http://jabber.org/protocol/disco#info" node="http://code.google.com/p/exodus#QgayPKawpkPSDYmwT/WM94uAlu0=">
          <identity name="Exodus 0.9.1" category="client" type="pc"/>
          <feature var="http://jabber.org/protocol/caps"/>
          <feature var="http://jabber.org/protocol/disco#info"/>
          <feature var="http://jabber.org/protocol/disco#items"/>
          <feature var="http://jabber.org/protocol/muc"/>
        </query>
      </iq>
    XML
    @dsl.send_caps
    # client writes a Client::Cap object but it's the same as a DiscoInfo
    # this is a hack to pass the same-class check in XMPPNode#eql?
    @client.expects(:write).with { |n| Blather::Stanza.import(n) == expected_stanza }
    @client.receive_data @stanza
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
    @dsl.pubsub.should be_instance_of Blather::DSL::PubSub
    @dsl.pubsub.host.should == jid.domain
  end
end
