require 'spec_helper'

describe Blather::Stream::Component do
  class MockServer; end
  module ServerMock
    def receive_data(data)
      @server ||= MockServer.new
      @server.receive_data data, self
    end
  end

  def mocked_server(times = nil, &block)
    @client ||= mock()
    @client.stubs(:unbind) unless @client.respond_to?(:unbind)
    @client.stubs(:jid=) unless @client.respond_to?(:jid=)

    port = 50000 - rand(1000)

    MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
    EventMachine::run {
      # Mocked server
      EventMachine::start_server '127.0.0.1', port, ServerMock

      # Blather::Stream connection
      EM.connect('127.0.0.1', port, Blather::Stream::Component, @client, @jid || 'comp.id', 'secret') { |c| @stream = c }
    }
  end

  it 'can be started' do
    client = mock()
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
        val.must_match(/stream:stream/)

      when :started
        server.send_data '<handshake/>'
        EM.stop
        val.must_equal "<handshake>#{Digest::SHA1.hexdigest('12345'+"secret")}</handshake>"

      end
    end
  end

  it 'starts the stream once the connection is complete' do
    mocked_server(1) { |val, _| EM.stop; val.must_match(/stream:stream/) }
  end

  it 'sends stanzas to the client when the stream is ready' do
    @client = mock(:post_init)
    @client.expects(:receive_data).with do |n|
      EM.stop
      n.kind_of? Blather::XMPPNode
    end

    state = nil
    mocked_server(2) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:component:accept' xmlns:stream='http://etherx.jabber.org/streams' id='12345'>"
        val.must_match(/stream:stream/)

      when :started
        server.send_data '<handshake/>'
        server.send_data "<message to='comp.id' from='d@e/f' type='chat' xml:lang='en'><body>Message!</body></message>"
        val.must_equal "<handshake>#{Digest::SHA1.hexdigest('12345'+"secret")}</handshake>"

      end
    end
  end

  it 'sends stanzas to the wire ensuring "from" is set' do
    client = mock()
    client.stubs(:jid)
    client.stubs(:jid=)
    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    comp = Blather::Stream::Component.new nil, client, 'jid.com', 'pass'
    comp.expects(:send_data).with { |s| s.must_match(/^<message[^>]*from="jid\.com"/) }
    comp.send msg
  end
end
