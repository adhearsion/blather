require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe 'Blather::Stream' do
  class MockServer; end
  module ServerMock
    def receive_data(data)
      @server ||= MockServer.new
      @server.receive_data data, self
    end
  end

  def mocked_server(times = nil, &block)
    @client ||= mock()
    @client.stubs(:jid=) unless @client.respond_to?(:jid=)

    MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
    EventMachine::run {
      # Mocked server
      EventMachine::start_server '127.0.0.1', 12345, ServerMock

      # Stream connection
      EM.connect('127.0.0.1', 12345, Stream, @client, @jid || JID.new('n@d/r'), 'pass') { |c| @stream = c }
    }
  end

  it 'can be started' do
    client = mock()
    params = [client, 'n@d/r', 'pass', 'host', 1234]
    EM.expects(:connect).with do |*parms|
      parms[0] == 'host'  &&
      parms[1] == 1234    &&
      parms[3] == client  &&
      parms[5] == 'pass'  &&
      parms[4] == JID.new('n@d/r')
    end

    Stream.start *(params)
  end

  it 'can figure out the host to use based on the jid' do
    client = mock()
    params = [client, 'n@d/r', 'pass', 'd', 5222]
    EM.expects(:connect).with do |*parms|
      parms[0] == 'd'     &&
      parms[1] == 5222    &&
      parms[3] == client  &&
      parms[5] == 'pass'  &&
      parms[4] == JID.new('n@d/r')
    end

    Stream.start client, 'n@d/r', 'pass'
  end

  it 'starts the stream once the connection is complete' do
    mocked_server(1) { |val, _| EM.stop; val.must_match(/stream:stream/) }
  end

  it 'sends stanzas to the client when the stream is ready' do
    @client = mock()
    @client.expects(:call).with do |n|
      EM.stop
      n.kind_of?(Stanza::Message) && @stream.ready?.must_equal(true)
    end

    mocked_server(1) do |val, server|
      val.must_match(/stream:stream/)
      server.send_data "<?xml version='1.0' ?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
      server.send_data "<message to='a@b/c' from='d@e/f' type='chat' xml:lang='en'><body>Message!</body></message>"
    end
  end

  it 'puts itself in the stopped state when stopped' do
    started = false
    mocked_server(2) do |val, server|
      if !started
        started = true
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      else
        EM.stop
        @stream.stopped?.must_equal false
        @stream.unbind
        @stream.stopped?.must_equal true

      end
    end
  end

  it 'will be in the negotiating state during feature negotiations' do
    state = nil
    @client = mock()
    @client.stubs(:stream_started)
    @client.expects(:call).with do |n|
      EM.stop
      state.must_equal(:negotiated) && @stream.negotiating?.must_equal(false)
    end

    mocked_server(2) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        true

      when :started
        state = :negotiated
        @stream.negotiating?.must_equal(true)
        server.send_data "<iq from='d' type='result' id='#{val[/id="([^"]+)"/,1]}' />"
        server.send_data "<message to='a@b/c' from='d@e/f' type='chat' xml:lang='en'><body>Message!</body></message>"
        true

      else
        EM.stop
        false

      end
    end
  end

  it 'stops when sent </stream:stream>' do
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0' xml:lang='en'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :stopped
        server.send_data '</stream:stream>'
        @stream.stopped?.must_equal false

      when :stopped
        EM.stop
        @stream.stopped?.must_equal true
        val.must_equal '</stream:stream>'

      else
        EM.stop
        false

      end
    end
  end

  it 'sends client an error on stream:error' do
    @client = mock()
    @client.expects(:call).with { |v| v.must_be_kind_of(StreamError) }
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :stopped
        server.send_data "<stream:error><conflict xmlns='urn:ietf:params:xml:ns:xmpp-streams' /></stream:error>"

      when :stopped
        EM.stop
        val.must_equal "</stream:stream>"

      else
        EM.stop
        false

      end
    end
  end

  it 'starts TLS when asked' do
    state = nil
    mocked_server(2) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        EM.stop
        val.must_match(/starttls/)

      else
        EM.stop
        false

      end
    end
  end

  it 'connects via SASL MD5 when asked' do
    Time.any_instance.stubs(:to_f).returns(1.1)
    state = nil

    mocked_server(5) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cmVhbG09InNvbWVyZWFsbSIsbm9uY2U9Ik9BNk1HOXRFUUdtMmhoIixxb3A9ImF1dGgiLGNoYXJzZXQ9dXRmLTgsYWxnb3JpdGhtPW1kNS1zZXNzCg==</challenge>"
        val.must_match(/auth.*DIGEST\-MD5/)

      when :auth_sent
        state = :response1_sent
        server.send_data "<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cnNwYXV0aD1lYTQwZjYwMzM1YzQyN2I1NTI3Yjg0ZGJhYmNkZmZmZAo=</challenge>"
        val.must_equal('<response xmlns="urn:ietf:params:xml:ns:xmpp-sasl">bm9uY2U9Ik9BNk1HOXRFUUdtMmhoIixjaGFyc2V0PXV0Zi04LHVzZXJuYW1lPSJuIixyZWFsbT0ic29tZXJlYWxtIixjbm9uY2U9Ijc3N2Q0NWJiYmNkZjUwZDQ5YzQyYzcwYWQ3YWNmNWZlIixuYz0wMDAwMDAwMSxxb3A9YXV0aCxkaWdlc3QtdXJpPSJ4bXBwL2QiLHJlc3BvbnNlPTZiNTlhY2Q1ZWJmZjhjZTA0NTYzMGFiMDU2Zjg3MTdm</response>')

      when :response1_sent
        state = :response2_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.must_match(%r{<response xmlns="urn:ietf:params:xml:ns:xmpp-sasl"\s?/>})

      when :response2_sent
        EM.stop
        state = :complete
        val.must_match(/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will connect via SSL PLAIN when asked' do
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>')

      when :auth_sent
        EM.stop
        state = :complete
        val.must_match(/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will connect via SSL ANONYMOUS when asked' do
    state = nil

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="ANONYMOUS">bg==</auth>')

      when :auth_sent
        EM.stop
        state = :complete
        val.must_match(/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'tried each possible mechanism until it fails completely' do
    state = nil
    @client = mock()
    @client.expects(:call).with do |n|
      n.must_be_kind_of(XMPPNode)
      n.element_name.must_equal 'failure'
    end

    mocked_server(5) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :failed_md5
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.must_match(/mechanism="DIGEST-MD5"/)

      when :failed_md5
        state = :failed_plain
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.must_match(/mechanism="PLAIN"/)

      when :failed_plain
        state = :failed_anon
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.must_match(/mechanism="ANONYMOUS"/)

      when :failed_anon
        EM.stop
        state = :complete
        val.must_match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'tries each mechanism until it succeeds' do
    state = nil
    mocked_server(4) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :failed_md5
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.must_match(/mechanism="DIGEST-MD5"/)

      when :failed_md5
        state = :plain_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.must_match(/mechanism="PLAIN"/)

      when :plain_sent
        EM.stop
        val.must_match(/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'sends client an error when an unknown mechanism is sent' do
    @client = mock()
    @client.expects(:call).with { |v| v.must_be_kind_of(Stream::SASL::UnknownMechanism) }
    started = false
    mocked_server(2) do |val, server|
      if !started
        started = true
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>UNKNOWN</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      else
        EM.stop
        val.must_match(/failure(.*)invalid\-mechanism/)

      end
    end
  end

  it 'will bind to a resource set by the server' do
    state = nil
    class Client; attr_accessor :jid; end
    @client = Client.new
    @jid = JID.new('n@d')

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :complete
        val =~ %r{<iq[^>]+id="([^"]+)"}
        server.send_data "<iq type='result' id='#{$1}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{@jid}/server_resource</jid></bind></iq>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"\s?/>})

      when :complete
        EM.stop
        @client.jid.must_equal JID.new('n@d/server_resource')

      else
        EM.stop
        false

      end
    end
  end

  it 'will bind to a resource set by the client' do
    state = nil
    class Client; attr_accessor :jid; end
    @client = Client.new
    @jid = JID.new('n@d/r')

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :complete
        val =~ %r{<iq[^>]+id="([^"]+)"}
        server.send_data "<iq type='result' id='#{$1}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{@jid}</jid></bind></iq>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><resource>r</resource></bind>})

      when :complete
        EM.stop
        @client.jid.must_equal JID.new('n@d/r')

      else
        EM.stop
        false

      end
    end
  end

  it 'will establish a session if requested' do
    state = nil
    @client = mock()
    @client.expects(:stream_started)

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :completed
        server.send_data "<iq from='d' type='result' id='#{val[/id="([^"]+)"/,1]}' />"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(%r{<iq id="[^"]+" type="set" to="d"><session xmlns="urn:ietf:params:xml:ns:xmpp-session"\s?/></iq>})

      when :completed
        EM.stop
        true

      else
        EM.stop
        false

      end
    end
  end

  it 'sends client an error on parse error' do
    @client = mock()
    @client.expects(:call).with { |v| v.must_be_kind_of(ParseError) }
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :parse_error
        server.send_data "</generate-parse-error>"

      when :parse_error
        EM.stop
        val.must_equal "</stream:stream>"

      else
        EM.stop
        false

      end
    end
  end
end
