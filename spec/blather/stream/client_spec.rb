require 'resolv'
require 'spec_helper'

describe Blather::Stream::Client do
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
    @client.stubs(:post_init) unless @client.respond_to?(:post_init)
    @client.stubs(:jid=) unless @client.respond_to?(:jid=)

    port = 50000 - rand(1000)

    MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
    EventMachine::run {
      EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

      # Mocked server
      EventMachine::start_server '127.0.0.1', port, ServerMock

      # Blather::Stream connection
      EM.connect('127.0.0.1', port, Blather::Stream::Client, @client, @jid || Blather::JID.new('n@d/r'), 'pass') { |c| @stream = c }
    }
  end


  it 'can be started' do
    client = mock()
    params = [client, 'n@d/r', 'pass', 'host', 1234]
    EM.expects(:connect).with do |*parms|
      parms[0].must_equal 'host'
      parms[1].must_equal 1234
      parms[3].must_equal client
      parms[5].must_equal 'pass'
      parms[4].must_equal Blather::JID.new('n@d/r')
    end

    Blather::Stream::Client.start *params
  end

  it 'attempts to find the SRV record if a host is not provided' do
    dns = mock(:sort! => nil, :empty? => false)
    dns.expects(:detect).yields(mock({
      :target => 'd',
      :port => 5222
    }))
    Resolv::DNS.expects(:open).yields(mock(:getresources => dns))

    client = Class.new
    EM.expects(:connect).with do |*parms|
      parms[0].must_equal 'd'
      parms[1].must_equal 5222
      parms[3].must_equal client
      parms[5].must_equal 'pass'
      parms[4].must_equal Blather::JID.new('n@d/r')
    end

    Blather::Stream::Client.start client, 'n@d/r', 'pass'
  end

  it 'will attempt as many connections as it takes' do
    dns = [mock(:target => 'd', :port => 5222), mock(:target => 'g', :port => 1234)]
    dns.stubs(:sort!) #ignore sorting
    Resolv::DNS.expects(:open).yields(mock(:getresources => dns))

    client = Class.new
    EM.expects(:connect).with do |*parms|
      raise Blather::Stream::NoConnection if parms[0] == 'd'
      parms[0].must_equal 'g'
      parms[1].must_equal 1234
      parms[3].must_equal client
      parms[5].must_equal 'pass'
      parms[4].must_equal Blather::JID.new('n@d/r')
    end
    Blather::Stream::Client.start client, 'n@d/r', 'pass'
  end

  it 'will not attempt to connect more often than necessary' do
    dns = [mock(:target => 'd', :port => 5222), mock()]
    dns.stubs(:sort!) #ignore sorting
    Resolv::DNS.expects(:open).yields(mock(:getresources => dns))

    client = Class.new
    EM.expects(:connect).with do |*parms|
      parms[0].must_equal 'd'
      parms[1].must_equal 5222
      parms[3].must_equal client
      parms[5].must_equal 'pass'
      parms[4].must_equal Blather::JID.new('n@d/r')
    end
    Blather::Stream::Client.start client, 'n@d/r', 'pass'
  end

  it 'can figure out the host to use based on the jid' do
    Resolv::DNS.expects(:open).yields(mock(:getresources => mock(:empty? => true)))
    client = Class.new
    params = [client, 'n@d/r', 'pass', nil, 5222]
    EM.expects(:connect).with do |*parms|
      parms[0].must_equal 'd'
      parms[1].must_equal 5222
      parms[3].must_equal client
      parms[5].must_equal 'pass'
      parms[4].must_equal Blather::JID.new('n@d/r')
    end

    Blather::Stream::Client.start client, 'n@d/r', 'pass'
  end

  it 'raises a NoConnection exception if the connection is unbound before it can be completed' do
    proc do
      EventMachine::run {
        EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

        Blather::Stream::Client.start @client, @jid || Blather::JID.new('n@d/r'), 'pass', '127.0.0.1', 50000 - rand(1000)
      }
    end.must_raise Blather::Stream::ConnectionFailed
  end

  it 'starts the stream once the connection is complete' do
    mocked_server(1) { |val, _| EM.stop; val.must_match(/stream:stream/) }
  end

  it 'sends stanzas to the client when the stream is ready' do
    @client = mock()
    @client.expects(:receive_data).with do |n|
      EM.stop
      n.must_be_kind_of Blather::Stanza::Message
    end

    mocked_server(1) do |val, server|
      val.must_match(/stream:stream/)
      server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
      server.send_data "<message to='a@b/c' from='d@e/f' type='chat' xml:lang='en'><body>Message!</body></message>"
    end
  end

  it 'puts itself in the stopped state and calls @client.unbind when unbound' do
    @client = mock()
    @client.expects(:unbind).at_least_once

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
    @client.expects(:receive_data).with do |n|
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
        @stream.negotiating?.must_equal true
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
    @client.expects(:receive_data).with do |v|
      v.name.must_equal :conflict
      v.text.must_equal 'Already signed in'
      v.to_s.must_equal "Stream Error (conflict): #{v.text}"
    end

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
        server.send_data "<stream:error><conflict xmlns='urn:ietf:params:xml:ns:xmpp-streams' />"
        server.send_data "<text xmlns='urn:ietf:params:xml:ns:xmpp-streams'>Already signed in</text></stream:error>"

      when :stopped
        EM.stop
        val.must_equal "</stream:stream>"

      else
        EM.stop
        false

      end
    end
  end

  it 'skips features it is unable to handle' do
    state = nil
    mocked_server() do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><auth xmlns='http://jabber.org/features/iq-auth'/><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
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

  it 'starts TLS when asked' do
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :tls
        @stream.expects(:start_tls)
        server.send_data "<proceed xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>"
        val.must_match(/starttls/)

      when :tls
        EM.stop
        true

      else
        EM.stop
        false

      end
    end
  end

  it 'will fail if TLS negotiation fails' do
    state = nil
    @client = mock()
    @client.expects(:receive_data).with { |v| v.must_be_kind_of Blather::Stream::TLS::TLSFailure }
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :tls
        @stream.expects(:start_tls).never
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-tls'/></stream:stream>"
        val.must_match(/starttls/)

      when :tls
        EM.stop
        val.must_equal "</stream:stream>"

      else
        EM.stop
        false

      end
    end
  end

  it 'will fail if a bad node comes through TLS negotiations' do
    state = nil
    @client = mock()
    @client.expects(:receive_data).with do |v|
      v.must_be_kind_of Blather::Stream::TLS::TLSFailure
    end
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :tls
        @stream.expects(:start_tls).never
        server.send_data "<foo-bar xmlns='urn:ietf:params:xml:ns:xmpp-tls'/></stream:stream>"
        val.must_match(/starttls/)

      when :tls
        EM.stop
        val.must_equal "</stream:stream>"

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
        val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="ANONYMOUS"/>')

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

  it 'connects via ANONYMOUS if the Blather::JID has a blank node' do
    state = nil
    @jid = Blather::JID.new '@d'

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="ANONYMOUS"/>')

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

  it 'fails if asked to connect via ANONYMOUS but the server does not support it' do
    state = nil
    @jid = Blather::JID.new '@d'
    @client = mock()
    @client.expects(:receive_data).with { |s| s.must_be_instance_of Blather::BlatherError }

    mocked_server(2) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        EM.stop
        val.must_match(/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'tries each possible mechanism until it fails completely' do
    state = nil
    @client = mock()
    @client.expects(:receive_data).with do |n|
      n.must_be_kind_of(Blather::SASLError)
      n.name.must_equal :not_authorized
    end

    mocked_server(5) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
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

  it 'will ignore methods it does not understand' do
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>CRAM-MD5</mechanism><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
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
=begin
  it 'sends client an error when an unknown mechanism is sent' do
    @client = mock()
    @client.expects(:receive_data).with { |v| v.must_be_kind_of(Blather::Stream::SASL::UnknownMechanism) }
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
=end
  %w[ aborted
      incorrect-encoding
      invalid-authzid
      invalid-mechanism
      mechanism-too-weak
      not-authorized
      temporary-auth-failure
  ].each do |error_type|
    it "fails on #{error_type}" do
      @client = mock()
      @client.expects(:receive_data).with do |n|
        n.name.must_equal error_type.gsub('-','_').to_sym
      end
      state = nil
      mocked_server(3) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
          val.must_match(/stream:stream/)

        when :started
          state = :auth_sent
          server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><#{error_type} /></failure>"
          val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>')

        when :auth_sent
          EM.stop
          state = :complete
          val.must_match(/\/stream:stream/)

        else
          EM.stop
          false

        end
      end
    end
  end

  it 'fails when an unknown node comes through during SASL negotiation' do
    @client = mock()
    @client.expects(:receive_data).with do |n|
      n.must_be_instance_of Blather::UnknownResponse
      n.node.element_name.must_equal 'foo-bar'
    end
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<foo-bar />"
        val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>')

      when :auth_sent
        EM.stop
        state = :complete
        val.must_match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will bind to a resource set by the server' do
    state = nil
    class Client; attr_accessor :jid; end
    @client = Client.new
    @jid = Blather::JID.new('n@d')

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :complete
        val =~ %r{<iq[^>]+id="([^"]+)"}
        server.send_data "<iq type='result' id='#{$1}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{@jid}/server_resource</jid></bind></iq>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"\s?/>})

      when :complete
        EM.stop
        @stream.jid.must_equal Blather::JID.new('n@d/server_resource')

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
    @jid = Blather::JID.new('n@d/r')

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :complete
        doc = parse_stanza val
        doc.xpath('/iq/bind_ns:bind/bind_ns:resource[.="r"]', :bind_ns => Blather::Stream::Resource::BIND_NS).wont_be_empty

        server.send_data "<iq type='result' id='#{doc.find_first('iq')['id']}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{@jid}</jid></bind></iq>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"

      when :complete
        EM.stop
        @stream.jid.must_equal Blather::JID.new('n@d/r')

      else
        EM.stop
        false

      end
    end
  end

  it 'will error out if the bind ID mismatches' do
    state = nil
    @jid = Blather::JID.new('n@d')
    @client = mock()

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :complete
        val =~ %r{<iq[^>]+id="([^"]+)"}
        @client.expects(:receive_data).with("BIND result ID mismatch. Expected: #{$1}. Received: #{$1}-bad")
        server.send_data "<iq type='result' id='#{$1}-bad'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{@jid}/server_resource</jid></bind></iq>"
        val.must_match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"\s?/>})

      when :complete
        EM.stop
        true

      else
        EM.stop
        false

      end
    end
  end

  it 'will return an error if resource binding errors out' do
    state = nil
    @client = mock()
    @client.expects(:receive_data).with do |n|
      n.name.must_equal :bad_request
    end
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :complete
        doc = parse_stanza val
        doc.xpath('/iq/bind_ns:bind/bind_ns:resource[.="r"]', :bind_ns => Blather::Stream::Resource::BIND_NS).wont_be_empty
        server.send_data "<iq type='error' id='#{doc.find_first('iq')['id']}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><resource>r</resource></bind><error type='modify'><bad-request xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error></iq>"

      when :complete
        EM.stop
        val.must_match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will return an error if an unknown node comes through during resouce binding' do
    state = nil
    @client = mock()
    @client.expects(:receive_data).with do |n|
      n.must_be_instance_of Blather::UnknownResponse
      n.node.element_name.must_equal 'foo-bar'
    end
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :complete
        doc = parse_stanza val
        doc.xpath('/iq/bind_ns:bind/bind_ns:resource[.="r"]', :bind_ns => Blather::Stream::Resource::BIND_NS).wont_be_empty
        server.send_data "<foo-bar />"

      when :complete
        EM.stop
        val.must_match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will establish a session if requested' do
    state = nil
    @client = mock()
    @client.expects(:post_init)

    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :completed
        doc = parse_stanza val
        doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).wont_be_empty
        server.send_data "<iq from='d' type='result' id='#{doc.find_first('iq')['id']}' />"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"

      when :completed
        EM.stop
        true

      else
        EM.stop
        false

      end
    end
  end

  it 'will return an error if session establishment errors out' do
    state = nil
    @client = mock()
    @client.expects(:receive_data).with do |n|
      n.name.must_equal :internal_server_error
    end
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :completed
        doc = parse_stanza val
        doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).wont_be_empty
        server.send_data "<iq from='d' type='error' id='#{doc.find_first('iq')['id']}'><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/><error type='wait'><internal-server-error xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error></iq>"

      when :completed
        EM.stop
        val.must_match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will return an error if an unknown node come through during session establishment' do
    state = nil
    @client = mock()
    @client.expects(:receive_data).with do |n|
      n.must_be_instance_of Blather::UnknownResponse
      n.node.element_name.must_equal 'foo-bar'
    end
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        val.must_match(/stream:stream/)

      when :started
        state = :completed
        doc = parse_stanza val
        doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).wont_be_empty
        server.send_data '<foo-bar />'

      when :completed
        EM.stop
        val.must_match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'sends client an error and reply to the server on parse error' do
    @client = mock()
    @client.expects(:receive_data).with do |v|
      v.must_be_kind_of Blather::ParseError
      v.message.must_match(/generate\-parse\-error/)
    end
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
        val.must_equal "<stream:error><xml-not-well-formed xmlns='urn:ietf:params:xml:ns:xmpp-streams'/></stream:error></stream:stream>"

      else
        EM.stop
        false

      end
    end
  end

  it 'sends stanzas to the wire ensuring "from" is the full JID if set' do
    client = mock()
    client.stubs(:jid)
    client.stubs(:jid=)
    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    msg.from = 'node@jid.com'
    comp = Blather::Stream::Client.new nil, client, 'node@jid.com/resource', 'pass'
    comp.expects(:send_data).with { |s| s.must_match(/^<message[^>]*from="node@jid\.com\/resource"/) }
    comp.send msg
  end

  it 'sends stanzas to the wire leaving "from" nil if not set' do
    client = mock()
    client.stubs(:jid)
    client.stubs(:jid=)
    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    comp = Blather::Stream::Client.new nil, client, 'node@jid.com/resource', 'pass'
    comp.expects(:send_data).with { |s| s.wont_match(/^<message[^>]*from=/); true }
    comp.send msg
  end

  it 'sends xml without formatting' do
    client = mock()
    client.stubs(:jid)
    client.stubs(:jid=)

    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    msg.xhtml = '<i>xhtml</i> body'

    comp = Blather::Stream::Client.new nil, client, 'node@jid.com/resource', 'pass'
    comp.expects(:send_data).with { |s| s.wont_match(/\n/); true }
    comp.send msg
  end
end
