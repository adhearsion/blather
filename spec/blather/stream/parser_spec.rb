require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe Blather::Stream::Parser do
  before do
    @client = Class.new do
      attr_reader :data
      def stopped?; false; end
      def receive(data)
        @data ||= []
        @data << data
      end
    end.new
    @parser = Blather::Stream::Parser.new @client
  end

  after { @client = @parser = nil}

  def check_parse(data)
    @parser.receive_data data
    @client.data.size.must_equal 1
    @client.data[0].to_s.gsub(/\n\s*/,'').must_equal data
  end

  it 'handles fragmented parsing' do
    @parser.receive_data '<foo>'
    @parser.receive_data '<bar/>'
    @parser.receive_data '</foo>'
    @client.data.size.must_equal 1
    @client.data[0].to_s.gsub(/\n\s*/,'').must_equal '<foo><bar/></foo>'
  end

  it 'handles a basic example' do
    check_parse "<foo/>"
  end

  it 'handles a basic namespace definition' do
    check_parse '<foo xmlns="bar:baz"/>'
  end

  it 'handles multiple namespace definitions' do
    check_parse '<foo xmlns="bar:baz" xmlns:bar="baz"/>'
  end

  it 'handles prefix namespacing' do
    check_parse '<bar:foo xmlns="bar:baz" xmlns:bar="baz"/>'
  end

  it 'handles namespaces with children' do
    check_parse "<foo xmlns=\"bar:baz\"><bar/></foo>"
  end

  it 'handles multiple namespaces with children' do
    check_parse "<foo xmlns=\"bar:baz\" xmlns:bar=\"baz\"><bar/></foo>"
  end

  it 'handles prefix namespaces with children' do
    check_parse "<bar:foo xmlns=\"bar:baz\" xmlns:bar=\"baz\"><bar/></bar:foo>"
  end

  it 'handles prefix namespaces with children in the namespace' do
    check_parse "<bar:foo xmlns=\"bar:baz\" xmlns:bar=\"baz\"><bar:bar/></bar:foo>"
  end

  it 'handles prefix namespaces with children in the namespace' do
    check_parse "<bar:foo xmlns=\"bar:baz\" xmlns:bar=\"baz\"><baz><bar:buz/></baz></bar:foo>"
  end

  it 'handles attributes' do
    check_parse '<foo bar="baz"/>'
  end

  it 'handles character input' do
    check_parse '<foo>bar baz fizbuz</foo>'
  end

  it 'handles a complex input' do
    data = [
      '<message type="error" id="another-id">',
        '<error type="modify">',
          '<undefined-condition xmlns="urn:ietf:params:xml:ns:xmpp-stanzas"/>',
          '<text xmlns="urn:ietf:params:xml:ns:xmpp-stanzas">Some special application diagnostic information...</text>',
          '<special-application-condition xmlns="application-ns"/>',
        "</error>",
      "</message>"
    ]
    data.each { |d| @parser.receive_data d }
    @client.data.size.must_equal 1
    @client.data[0].to_s.split("\n").map{|n|n.strip}.must_equal data
    @client.data[0].xpath('//*[namespace-uri()="urn:ietf:params:xml:ns:xmpp-stanzas"]').size.must_equal 2
  end

  it 'responds with stream:stream as a separate response' do
    data = [
      '<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="example.com" version="1.0">',
      '<foo/>'
    ]
    data.each { |d| @parser.receive_data d }
    @client.data.size.must_equal 2
    @client.data[0].document.xpath('/stream:stream[@to="example.com" and @version="1.0"]', 'xmlns' => 'jabber:client', 'stream' => 'http://etherx.jabber.org/streams').size.must_equal 1
    @client.data[1].to_s.must_equal '<foo/>'
  end

  it 'response with stream:end when receiving </stream:stream>' do
    @parser.receive_data '<stream:stream xmlns:stream="http://etherx.jabber.org/streams"/>'
    @client.data.size.must_equal 2
    @client.data[1].to_s.must_equal '<stream:end/>'
  end

  it 'raises ParseError when an error is sent' do
    lambda { @parser.receive_data "<stream:stream>" }.must_raise(Blather::ParseError)
  end

  it 'handles stream stanzas without an issue' do
    data = [
      '<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="example.com" version="1.0">',
      '<stream:features/>'
    ]
    data.each { |d| @parser.receive_data d }
    @client.data.size.must_equal 2
    @client.data[0].document.xpath('/stream:stream[@to="example.com" and @version="1.0"]', 'xmlns' => 'jabber:client', 'stream' => 'http://etherx.jabber.org/streams').size.must_equal 1
    @client.data[1].to_s.must_equal '<stream:features xmlns:stream="http://etherx.jabber.org/streams"/>'
  end
end
