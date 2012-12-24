require 'resolv'
require 'spec_helper'

describe Blather::Stream::Client do
  let(:client)      { mock 'Client' }
  let(:server_port) { 50000 - rand(1000) }
  let(:jid)         { Blather::JID.new 'n@d/r' }

  before do
    [:unbind, :post_init, :jid=].each do |m|
      client.stubs(m) unless client.respond_to?(m)
    end
    client.stubs(:jid).returns jid
  end

  def mocked_server(times = nil, &block)
    MockServer.any_instance.expects(:receive_data).send(*(times ? [:times, times] : [:at_least, 1])).with &block
    EventMachine::run {
      EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

      # Mocked server
      EventMachine::start_server '127.0.0.1', server_port, ServerMock

      # Blather::Stream connection
      EM.connect('127.0.0.1', server_port, Blather::Stream::Client, client, jid, 'pass') { |c| @stream = c }
    }
  end

  it 'can be started' do
    params = [client, 'n@d/r', 'pass', 'host', 1234]
    EM.expects(:connect).with do |*parms|
      parms[0].should == 'host'
      parms[1].should == 1234
      parms[3].should == client
      parms[5].should == 'pass'
      parms[4].should == Blather::JID.new('n@d/r')
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
      parms[0].should == 'd'
      parms[1].should == 5222
      parms[3].should == client
      parms[5].should == 'pass'
      parms[4].should == Blather::JID.new('n@d/r')
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
      parms[0].should == 'g'
      parms[1].should == 1234
      parms[3].should == client
      parms[5].should == 'pass'
      parms[4].should == Blather::JID.new('n@d/r')
    end
    Blather::Stream::Client.start client, 'n@d/r', 'pass'
  end

  it 'will not attempt to connect more often than necessary' do
    dns = [mock(:target => 'd', :port => 5222), mock()]
    dns.stubs(:sort!) #ignore sorting
    Resolv::DNS.expects(:open).yields(mock(:getresources => dns))

    client = Class.new
    EM.expects(:connect).with do |*parms|
      parms[0].should == 'd'
      parms[1].should == 5222
      parms[3].should == client
      parms[5].should == 'pass'
      parms[4].should == Blather::JID.new('n@d/r')
    end
    Blather::Stream::Client.start client, 'n@d/r', 'pass'
  end

  it 'can figure out the host to use based on the jid' do
    Resolv::DNS.expects(:open).yields(mock(:getresources => mock(:empty? => true)))
    client = Class.new
    params = [client, 'n@d/r', 'pass', nil, 5222]
    EM.expects(:connect).with do |*parms|
      parms[0].should == 'd'
      parms[1].should == 5222
      parms[3].should == client
      parms[5].should == 'pass'
      parms[4].should == Blather::JID.new('n@d/r')
    end

    Blather::Stream::Client.start client, 'n@d/r', 'pass'
  end

  it 'raises a NoConnection exception if the connection is unbound before it can be completed' do
    proc do
      EventMachine::run {
        EM.add_timer(0.5) { EM.stop if EM.reactor_running? }

        Blather::Stream::Client.start client, jid, 'pass', '127.0.0.1', 50000 - rand(1000)
      }
    end.should raise_error Blather::Stream::ConnectionFailed
  end

  it 'starts the stream once the connection is complete' do
    mocked_server(1) { |val, _| EM.stop; val.should match(/stream:stream/) }
  end

  it 'sends stanzas to the client when the stream is ready' do
    client.expects(:receive_data).with do |n|
      EM.stop
      n.should be_kind_of Blather::Stanza::Message
    end

    mocked_server(1) do |val, server|
      val.should match(/stream:stream/)
      server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
      server.send_data "<message to='a@b/c' from='d@e/f' type='chat' xml:lang='en'><body>Message!</body></message>"
    end
  end

  it 'puts itself in the stopped state and calls @client.unbind when unbound' do
    client.expects(:unbind).at_least_once

    started = false
    mocked_server(2) do |val, server|
      if !started
        started = true
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.should match(/stream:stream/)

      else
        EM.stop
        @stream.should_not be_stopped
        @stream.unbind
        @stream.should be_stopped

      end
    end
  end

  it 'will be in the negotiating state during feature negotiations' do
    state = nil

    client.expects(:receive_data).with do |n|
      EM.stop
      state.should == :negotiated
      @stream.negotiating?.should == false
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
        @stream.negotiating?.should == true
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
        val.should match(/stream:stream/)

      when :started
        state = :stopped
        server.send_data '</stream:stream>'
        @stream.stopped?.should == false

      when :stopped
        EM.stop
        @stream.stopped?.should == true
        val.should == '</stream:stream>'

      else
        EM.stop
        false

      end
    end
  end

  it 'sends client an error on stream:error' do
    client.expects(:receive_data).with do |v|
      v.name.should == :conflict
      v.text.should == 'Already signed in'
      v.to_s.should == "Stream Error (conflict): #{v.text}"
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :stopped
        server.send_data "<stream:error><conflict xmlns='urn:ietf:params:xml:ns:xmpp-streams' />"
        server.send_data "<text xmlns='urn:ietf:params:xml:ns:xmpp-streams'>Already signed in</text></stream:error>"

      when :stopped
        EM.stop
        val.should == "</stream:stream>"

      else
        EM.stop
        false

      end
    end
  end

  it 'skips features it is unable to handle' do
    state = nil
    mocked_server do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><auth xmlns='http://jabber.org/features/iq-auth'/><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        EM.stop
        val.should match(/starttls/)

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
        val.should match(/stream:stream/)

      when :started
        state = :tls
        @stream.expects(:start_tls)
        server.send_data "<proceed xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>"
        val.should match(/starttls/)

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
    client.expects(:receive_data).with { |v| v.should be_kind_of Blather::Stream::TLS::TLSFailure }

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :tls
        @stream.expects(:start_tls).never
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-tls'/></stream:stream>"
        val.should match(/starttls/)

      when :tls
        EM.stop
        val.should == "</stream:stream>"

      else
        EM.stop
        false

      end
    end
  end

  it 'will fail if a bad node comes through TLS negotiations' do
    client.expects(:receive_data).with do |v|
      v.should be_kind_of Blather::Stream::TLS::TLSFailure
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :tls
        @stream.expects(:start_tls).never
        server.send_data "<foo-bar xmlns='urn:ietf:params:xml:ns:xmpp-tls'/></stream:stream>"
        val.should match(/starttls/)

      when :tls
        EM.stop
        val.should == "</stream:stream>"

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
        val.should match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cmVhbG09InNvbWVyZWFsbSIsbm9uY2U9Ik9BNk1HOXRFUUdtMmhoIixxb3A9ImF1dGgiLGNoYXJzZXQ9dXRmLTgsYWxnb3JpdGhtPW1kNS1zZXNzCg==</challenge>"
        val.should match(/auth.*DIGEST\-MD5/)

      when :auth_sent
        state = :response1_sent
        server.send_data "<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cnNwYXV0aD1lYTQwZjYwMzM1YzQyN2I1NTI3Yjg0ZGJhYmNkZmZmZAo=</challenge>"
        val.should ==('<response xmlns="urn:ietf:params:xml:ns:xmpp-sasl">bm9uY2U9Ik9BNk1HOXRFUUdtMmhoIixjaGFyc2V0PXV0Zi04LHVzZXJuYW1lPSJuIixyZWFsbT0ic29tZXJlYWxtIixjbm9uY2U9Ijc3N2Q0NWJiYmNkZjUwZDQ5YzQyYzcwYWQ3YWNmNWZlIixuYz0wMDAwMDAwMSxxb3A9YXV0aCxkaWdlc3QtdXJpPSJ4bXBwL2QiLHJlc3BvbnNlPTZiNTlhY2Q1ZWJmZjhjZTA0NTYzMGFiMDU2Zjg3MTdm</response>')

      when :response1_sent
        state = :response2_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.should match(%r{<response xmlns="urn:ietf:params:xml:ns:xmpp-sasl"\s?/>})

      when :response2_sent
        EM.stop
        state = :complete
        val.should match(/stream:stream/)

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
        val.should match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        Nokogiri::XML(val).to_xml.should == Nokogiri::XML('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>').to_xml

      when :auth_sent
        EM.stop
        state = :complete
        val.should match(/stream:stream/)

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
        val.should match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        Nokogiri::XML(val).to_xml.should == Nokogiri::XML('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="ANONYMOUS"/>').to_xml

      when :auth_sent
        EM.stop
        state = :complete
        val.should match(/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  context "if the JID node is blank" do
    let(:jid) { Blather::JID.new '@d' }

    it 'connects via ANONYMOUS if the Blather::JID has a blank node' do
      state = nil
      mocked_server(3) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
          val.should match(/stream:stream/)

        when :started
          state = :auth_sent
          server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
          Nokogiri::XML(val).to_xml.should == Nokogiri::XML('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="ANONYMOUS"/>').to_xml

        when :auth_sent
          EM.stop
          state = :complete
          val.should match(/stream:stream/)

        else
          EM.stop
          false

        end
      end
    end

    it 'fails if asked to connect via ANONYMOUS but the server does not support it' do
      client.expects(:receive_data).with { |s| s.should be_instance_of Blather::BlatherError }

      state = nil
      mocked_server(2) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
          server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
          val.should match(/stream:stream/)

        when :started
          EM.stop
          val.should match(/stream:stream/)

        else
          EM.stop
          false

        end
      end
    end
  end

  it 'tries each possible mechanism until it fails completely' do
    client.expects(:receive_data).with do |n|
      n.should be_kind_of(Blather::SASLError)
      n.name.should == :not_authorized
    end

    state = nil
    mocked_server(5) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :failed_md5
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.should match(/mechanism="DIGEST-MD5"/)

      when :failed_md5
        state = :failed_plain
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.should match(/mechanism="PLAIN"/)

      when :failed_plain
        state = :failed_anon
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.should match(/mechanism="ANONYMOUS"/)

      when :failed_anon
        EM.stop
        state = :complete
        val.should match(/\/stream:stream/)

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
        val.should match(/stream:stream/)

      when :started
        state = :failed_md5
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.should match(/mechanism="DIGEST-MD5"/)

      when :failed_md5
        state = :plain_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.should match(/mechanism="PLAIN"/)

      when :plain_sent
        EM.stop
        val.should match(/stream:stream/)

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
        val.should match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        Nokogiri::XML(val).to_xml.should == Nokogiri::XML('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>').to_xml

      when :auth_sent
        EM.stop
        state = :complete
        val.should match(/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  %w[ aborted
      incorrect-encoding
      invalid-authzid
      invalid-mechanism
      mechanism-too-weak
      not-authorized
      temporary-auth-failure
  ].each do |error_type|
    it "fails on #{error_type}" do
      client.expects(:receive_data).with do |n|
        n.name.should == error_type.gsub('-','_').to_sym
      end

      state = nil
      mocked_server(3) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
          val.should match(/stream:stream/)

        when :started
          state = :auth_sent
          server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><#{error_type} /></failure>"
          Nokogiri::XML(val).to_xml.should == Nokogiri::XML('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>').to_xml

        when :auth_sent
          EM.stop
          state = :complete
          val.should match(/\/stream:stream/)

        else
          EM.stop
          false

        end
      end
    end
  end

  it 'fails when an unknown node comes through during SASL negotiation' do
    client.expects(:receive_data).with do |n|
      n.should be_instance_of Blather::UnknownResponse
      n.node.element_name.should == 'foo-bar'
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :auth_sent
        server.send_data "<foo-bar />"
        Nokogiri::XML(val).to_xml.should == Nokogiri::XML('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>').to_xml

      when :auth_sent
        EM.stop
        state = :complete
        val.should match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  context "when the JID doesn't set a resource" do
    let(:jid) { Blather::JID.new 'n@d' }

    it 'will bind to a resource set by the server' do
      state = nil
      mocked_server(3) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
          server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
          val.should match(/stream:stream/)

        when :started
          state = :complete
          val =~ %r{<iq[^>]+id="([^"]+)"}
          server.send_data "<iq type='result' id='#{$1}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{jid}/server_resource</jid></bind></iq>"
          server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
          val.should match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"\s?/>})

        when :complete
          EM.stop
          @stream.jid.should == Blather::JID.new('n@d/server_resource')

        else
          EM.stop
          false

        end
      end
    end

    it 'will error out if the bind ID mismatches' do
      state = nil

      mocked_server(3) do |val, server|
        case state
        when nil
          state = :started
          server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
          server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
          val.should match(/stream:stream/)

        when :started
          state = :complete
          val =~ %r{<iq[^>]+id="([^"]+)"}
          client.expects(:receive_data).with("BIND result ID mismatch. Expected: #{$1}. Received: #{$1}-bad")
          server.send_data "<iq type='result' id='#{$1}-bad'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{jid}/server_resource</jid></bind></iq>"
          val.should match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"\s?/>})

        when :complete
          EM.stop
          true

        else
          EM.stop
          false

        end
      end
    end
  end

  it 'will bind to a resource set by the client' do
    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :complete
        doc = parse_stanza val
        doc.xpath('/iq/bind_ns:bind/bind_ns:resource[.="r"]', :bind_ns => Blather::Stream::Resource::BIND_NS).should_not be_empty

        server.send_data "<iq type='result' id='#{doc.find_first('iq')['id']}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{jid}</jid></bind></iq>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"

      when :complete
        EM.stop
        @stream.jid.should == Blather::JID.new('n@d/r')

      else
        EM.stop
        false

      end
    end
  end

  it 'will return an error if resource binding errors out' do
    client.expects(:receive_data).with do |n|
      n.name.should == :bad_request
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :complete
        doc = parse_stanza val
        doc.xpath('/iq/bind_ns:bind/bind_ns:resource[.="r"]', :bind_ns => Blather::Stream::Resource::BIND_NS).should_not be_empty
        server.send_data "<iq type='error' id='#{doc.find_first('iq')['id']}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><resource>r</resource></bind><error type='modify'><bad-request xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error></iq>"

      when :complete
        EM.stop
        val.should match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will return an error if an unknown node comes through during resouce binding' do
    client.expects(:receive_data).with do |n|
      n.should be_instance_of Blather::UnknownResponse
      n.node.element_name.should == 'foo-bar'
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :complete
        doc = parse_stanza val
        doc.xpath('/iq/bind_ns:bind/bind_ns:resource[.="r"]', :bind_ns => Blather::Stream::Resource::BIND_NS).should_not be_empty
        server.send_data "<foo-bar />"

      when :complete
        EM.stop
        val.should match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will establish a session if requested' do
    client.expects(:post_init)

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :completed
        doc = parse_stanza val
        doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).should_not be_empty
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
    client.expects(:receive_data).with do |n|
      n.name.should == :internal_server_error
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :completed
        doc = parse_stanza val
        doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).should_not be_empty
        server.send_data "<iq from='d' type='error' id='#{doc.find_first('iq')['id']}'><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/><error type='wait'><internal-server-error xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error></iq>"

      when :completed
        EM.stop
        val.should match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'will return an error if an unknown node come through during session establishment' do
    client.expects(:receive_data).with do |n|
      n.should be_instance_of Blather::UnknownResponse
      n.node.element_name.should == 'foo-bar'
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :completed
        doc = parse_stanza val
        doc.find('/iq[@type="set" and @to="d"]/sess_ns:session', :sess_ns => Blather::Stream::Session::SESSION_NS).should_not be_empty
        server.send_data '<foo-bar />'

      when :completed
        EM.stop
        val.should match(/\/stream:stream/)

      else
        EM.stop
        false

      end
    end
  end

  it 'sends client an error and reply to the server on parse error' do
    client.expects(:receive_data).with do |v|
      v.should be_kind_of Blather::ParseError
      v.message.should match(/generate\-parse\-error/)
    end

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :started
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>"
        server.send_data "<stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind' /></stream:features>"
        val.should match(/stream:stream/)

      when :started
        state = :parse_error
        server.send_data "</generate-parse-error>"

      when :parse_error
        EM.stop
        val.should == "<stream:error><xml-not-well-formed xmlns='urn:ietf:params:xml:ns:xmpp-streams'/></stream:error></stream:stream>"

      else
        EM.stop
        false

      end
    end
  end

  it 'sends stanzas to the wire ensuring "from" is the full JID if set' do
    EM.expects(:next_tick).at_least(1).yields

    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    msg.from = 'node@jid.com'
    comp = Blather::Stream::Client.new nil, client, 'node@jid.com/resource', 'pass'
    comp.expects(:send_data).with { |s| s.should match(/^<message[^>]*from="node@jid\.com\/resource"/) }
    comp.send msg
  end

  it 'sends stanzas to the wire leaving "from" nil if not set' do
    EM.expects(:next_tick).at_least(1).yields

    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    comp = Blather::Stream::Client.new nil, client, 'node@jid.com/resource', 'pass'
    comp.expects(:send_data).with { |s| s.should_not match(/^<message[^>]*from=/); true }
    comp.send msg
  end

  it 'sends xml without formatting' do
    EM.expects(:next_tick).at_least(1).yields

    msg = Blather::Stanza::Message.new 'to@jid.com', 'body'
    msg.xhtml = '<i>xhtml</i> body'

    comp = Blather::Stream::Client.new nil, client, 'node@jid.com/resource', 'pass'
    comp.expects(:send_data).with { |s| s.should_not match(/\n/); true }
    comp.send msg
  end

  it 'tries to register if initial authentication failed but in-band registration enabled' do
    EM.expects(:next_tick).at_least(1).yields

    state = nil
    mocked_server(4) do |val, server|
      case state
      when nil
        state = :sasl_failed
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms><register xmlns='http://jabber.org/features/iq-register'/></stream:features>"
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.should match(/stream:stream/)
      when :sasl_failed
        state = :registered
        server.send_data "<iq type='result'/>"
        val.should match(/jabber:iq:register/)
      when :registered
        state = :authenticated
        server.send_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl' />"
        val.should match(/mechanism="PLAIN"/)
      when :authenticated
        EM.stop
        val.should match(/stream:stream/)
      else
        EM.stop
        false
      end
    end
  end

  it 'fails when in-band registration failed' do
    client.expects(:receive_data).with { |n| n.should be_instance_of Blather::BlatherError }

    state = nil
    mocked_server(3) do |val, server|
      case state
      when nil
        state = :sasl_failed
        server.send_data "<?xml version='1.0'?><stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>"
        server.send_data "<stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms><register xmlns='http://jabber.org/features/iq-register'/></stream:features>"
        server.send_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized /></failure>"
        val.should match(/stream:stream/)
      when :sasl_failed
        state = :registration_failed
        server.send_data "<iq type='error'><query /><error code='409' type='cancel'><conflict xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/></error></iq>"
        val.should match(/jabber:iq:register/)
      when :registration_failed
        EM.stop
        val.should match(/\/stream:stream/)
      else
        EM.stop
        false
      end
    end
  end
end
