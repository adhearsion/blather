require 'spec_helper'

describe Blather::Stream::Component do
  before {pending}
  let(:client)      { mock 'Client' }
  let(:server_port) { 50000 - rand(1000) }
  let(:jid)         { 'comp.id' }

  before do
    [:unbind, :post_init, :jid=].each do |m|
      client.stubs(m) unless client.respond_to?(m)
    end
    client.stubs(:jid).returns jid
  end

  def mocked_server(times = nil, &block)
    MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
    EventMachine::run {
      # Mocked server
      EventMachine::start_server '127.0.0.1', server_port, ServerMock

      # Blather::Stream connection
      EM.connect('127.0.0.1', server_port, Blather::Stream::Component, client, jid, 'secret') { |c| @stream = c }
    }
  end

  after { sleep 0.1; @stream.cleanup if @stream }

  it 'can be started' do
    params = [client, 'comp.id', 'secret', 'host', 1234]
    EM.expects(:connect).with do |*parms|
      parms[0] == 'host'    &&
      parms[1] == 1234      &&
      parms[3] == client    &&
      parms[4] == 'comp.id'
    end

    Blather::Stream::Component.start *params
  end

  it 'shakes hands with the server' do
    state = nil
    mocked_server(2) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:component:accept' xmlns:stream='http://etherx.jabber.org/streams' id='12345'>"
        val.should match(/stream:stream/)

      when :started
        server.send_data '<handshake/>'
        EM.stop
        val.should == "<handshake>#{Digest::SHA1.hexdigest('12345'+"secret")}</handshake>"

      end
    end
  end

  it 'raises a NoConnection exception if the connection is unbound before it can be completed' do
    proc do
      EventMachine::run {
        EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

        Blather::Stream::Component.start client, jid, 'pass', '127.0.0.1', 50000 - rand(1000)
      }
    end.should raise_error Blather::Stream::ConnectionFailed
  end

  it 'starts the stream once the connection is complete' do
    mocked_server(1) { |val, _| EM.stop; val.should match(/stream:stream/) }
  end

  it 'sends stanzas to the client when the stream is ready' do
    client.stubs :post_init
    client.expects(:receive_data).with do |n|
      EM.stop
      n.kind_of? Blather::XMPPNode
    end

    state = nil
    mocked_server(2) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:component:accept' xmlns:stream='http://etherx.jabber.org/streams' id='12345'>"
        val.should match(/stream:stream/)

      when :started
        server.send_data '<handshake/>'
        server.send_data "<message to='comp.id' from='d@e/f' type='chat' xml:lang='en'><body>Message!</body></message>"
        val.should == "<handshake>#{Digest::SHA1.hexdigest('12345'+"secret")}</handshake>"

      end
    end
  end

  it 'sends stanzas to the wire ensuring "from" is set' do
    EM.expects(:next_tick).at_least(1).yields

    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    comp = Blather::Stream::Component.new nil, client, 'jid.com', 'pass'
    comp.expects(:send_data).with { |s| s.should match(/^<message[^>]*from="jid\.com"/) }
    comp.send msg
  end
end
