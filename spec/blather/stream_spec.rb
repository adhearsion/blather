require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe 'Blather::Stream' do
  class MockStream; include Stream; end
  def mock_stream(&block)
    @client = mock()
    @client.stubs(:jid=)
    stream = MockStream.new @client, JID.new('n@d/r'), 'pass'

    stream.expects(:send_data).at_least(1).with &block
    stream
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
    s = mock_stream { |d| d =~ /stream:stream/ }
    s.connection_completed
  end

  it 'starts TLS when asked' do
    state = nil
    @stream = mock_stream do |val|
      case
      when state.nil? && val =~ /stream:stream/   then state = :started
      when state == :started && val =~ /starttls/ then true
      else false
      end
    end
    @stream.connection_completed
    @stream.receive_data "<stream:stream><stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls' /></stream:features>"
  end

  it 'connects via SASL MD5 when asked' do
    Time.any_instance.stubs(:to_f).returns(1.1)

    state = nil
    client = mock()
    client.stubs(:jid=)
    stream = MockStream.new client, JID.new('n@d/r'), 'pass'

    stream.expects(:send_data).times(5).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism></mechanisms></stream:features>"
        true

      when :started
        val.must_match(/auth.*DIGEST\-MD5/)
        state = :auth_sent
        stream.receive_data "<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cmVhbG09InNvbWVyZWFsbSIsbm9uY2U9Ik9BNk1HOXRFUUdtMmhoIixxb3A9ImF1dGgiLGNoYXJzZXQ9dXRmLTgsYWxnb3JpdGhtPW1kNS1zZXNzCg==</challenge>"
        true

      when :auth_sent
        val.must_equal('<response xmlns="urn:ietf:params:xml:ns:xmpp-sasl">bm9uY2U9Ik9BNk1HOXRFUUdtMmhoIixjaGFyc2V0PXV0Zi04LHVzZXJuYW1lPSJuIixyZWFsbT0ic29tZXJlYWxtIixjbm9uY2U9Ijc3N2Q0NWJiYmNkZjUwZDQ5YzQyYzcwYWQ3YWNmNWZlIixuYz0wMDAwMDAwMSxxb3A9YXV0aCxkaWdlc3QtdXJpPSJ4bXBwL2QiLHJlc3BvbnNlPTZiNTlhY2Q1ZWJmZjhjZTA0NTYzMGFiMDU2Zjg3MTdm</response>')
        state = :response1_sent
        stream.receive_data "<challenge xmlns='urn:ietf:params:xml:ns:xmpp-sasl'>cnNwYXV0aD1lYTQwZjYwMzM1YzQyN2I1NTI3Yjg0ZGJhYmNkZmZmZAo=</challenge>"
        true

      when :response1_sent
        val.must_equal('<response xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/>')
        state = :response2_sent
        stream.receive_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl'/>"
        true

      when :response2_sent
        val.must_match(/stream:stream/)
        state = :complete
        true

      else
        false

      end
    end
    stream.connection_completed
  end

  it 'will connect via SSL PLAIN when asked' do
    state = nil
    client = mock()
    client.stubs(:jid=)
    stream = MockStream.new client, JID.new('n@d/r'), 'pass'

    stream.expects(:send_data).times(3).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>PLAIN</mechanism></mechanisms></stream:features>"
        true

      when :started
        val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">bkBkAG4AcGFzcw==</auth>')
        state = :auth_sent
        stream.receive_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl'/>"
        true

      when :auth_sent
        val.must_match(/stream:stream/)
        state = :complete
        true

      else
        false

      end
    end
    stream.connection_completed
  end

  it 'will connect via SSL ANONYMOUS when asked' do
    state = nil
    client = mock()
    client.stubs(:jid=)
    stream = MockStream.new client, JID.new('n@d/r'), 'pass'

    stream.expects(:send_data).times(3).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        true

      when :started
        val.must_equal('<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="ANONYMOUS">bg==</auth>')
        state = :auth_sent
        stream.receive_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl'/>"
        true

      when :auth_sent
        val.must_match(/stream:stream/)
        state = :complete
        true

      else
        false

      end
    end
    stream.connection_completed
  end

  it 'tried each possible mechanism until it fails completely' do
    state = nil
    client = mock()
    client.stubs(:jid=)
    stream = MockStream.new client, JID.new('n@d/r'), 'pass'

    stream.expects(:send_data).times(5).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        true

      when :started
        val.must_match(/mechanism="DIGEST-MD5"/)
        state = :failed_md5
        stream.receive_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized/></failure>"
        true

      when :failed_md5
        val.must_match(/mechanism="PLAIN"/)
        state = :failed_plain
        stream.receive_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized/></failure>"
        true

      when :failed_plain
        val.must_match(/mechanism="ANONYMOUS"/)
        state = :failed_anon
        stream.receive_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized/></failure>"
        true

      when :failed_anon
        val.must_match(/\/stream:stream/)
        state = :complete
        true

      else
        false

      end
    end
    stream.connection_completed
  end

  it 'tries each mechanism until it succeeds' do
    state = nil
    client = mock()
    client.stubs(:jid=)
    stream = MockStream.new client, JID.new('n@d/r'), 'pass'

    stream.expects(:send_data).times(4).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism><mechanism>PLAIN</mechanism><mechanism>ANONYMOUS</mechanism></mechanisms></stream:features>"
        true

      when :started
        val.must_match(/mechanism="DIGEST-MD5"/)
        state = :failed_md5
        stream.receive_data "<failure xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><not-authorized/></failure>"
        true

      when :failed_md5
        val.must_match(/mechanism="PLAIN"/)
        state = :plain_sent
        stream.receive_data "<success xmlns='urn:ietf:params:xml:ns:xmpp-sasl'/>"
        true

      when :plain_sent
        val.must_match(/stream:stream/)
        state = :complete
        true

      else
        false

      end
    end
    stream.connection_completed
  end

  it 'raises an exception when an unknown mechanism is sent' do
    state = nil
    client = mock()
    client.stubs(:jid=)
    stream = MockStream.new client, JID.new('n@d/r'), 'pass'

    stream.expects(:send_data).times(2).with do |val|
      if !state
        state = :started
        val.must_match(/stream:stream/)
        lambda do
          stream.receive_data "<stream:stream><stream:features><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>UNKNOWN</mechanism></mechanisms></stream:features>"
        end.must_raise(Stream::SASL::UnknownMechanism)

      else
        val.must_match(/failure(.*)invalid\-mechanism/)

      end
    end
    stream.connection_completed
  end

  it 'will bind to a resource set by the server' do
    state = nil
    class Client; attr_accessor :jid; end
    client = Client.new

    jid = JID.new('n@d')
    stream = MockStream.new client, jid, 'pass'

    stream.expects(:send_data).times(2).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/></stream:features>"
        true

      when :started
        val.must_match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"\s*/>})
        val =~ %r{<iq[^>]+id="([^"]+)"}
        state = :complete
        stream.receive_data "<iq type='result' id='#{$1}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{jid}/server_resource</jid></bind></iq>"
        client.jid.must_equal JID.new('n@d/server_resource')
        true

      else
        false

      end
    end
    stream.connection_completed
  end

  it 'will bind to a resource set by the client' do
    state = nil
    class Client; attr_accessor :jid; end
    client = Client.new

    jid = JID.new('n@d/r')
    stream = MockStream.new client, jid, 'pass'

    stream.expects(:send_data).times(2).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/></stream:features>"
        true

      when :started
        val.must_match(%r{<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><resource>r</resource></bind>})
        val =~ %r{<iq[^>]+id="([^"]+)"}
        state = :complete
        stream.receive_data "<iq type='result' id='#{$1}'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><jid>#{jid}</jid></bind></iq>"
        client.jid.must_equal JID.new('n@d/r')
        true

      else
        false

      end
    end
    stream.connection_completed
  end

  it 'will establish a session if requested' do
    state = nil
    client = mock()
    client.stubs(:jid=)
    stream = MockStream.new client, JID.new('n@d/r'), 'pass'

    client.expects(:stream_started)
    stream.expects(:send_data).times(2).with do |val|
      case state
      when nil
        val.must_match(/stream:stream/)
        state = :started
        stream.receive_data "<stream:stream><stream:features><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/></stream:features>"
        true

      when :started
        val.must_match('<iq id="[^"]+" type="set" to="d"><session xmlns="urn:ietf:params:xml:ns:xmpp-session"/></iq>')
        state = :completed
        stream.receive_data "<iq from='d' type='result' id='#{val[/id="([^"]+)"/,1]}'/>"
        true

      else
        false

      end
    end
    stream.connection_completed
  end
end
