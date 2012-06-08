require 'spec_helper'

describe Blather::Stream::Parser do
  let :client do
    Class.new do
      attr_reader :data
      attr_accessor :latch
      def stopped?; false; end
      def receive(node)
        @data ||= []
        @data << node
        latch.countdown!
      end
    end.new
  end

  subject { Blather::Stream::Parser.new client }

  def process(*data)
    client.latch = CountDownLatch.new 1
    data.each { |d| subject.receive_data d }
    client.latch.wait(2).should be_true
  end

  def check_parse(data)
    process data
    client.data.size.should == 1
    client.data[0].to_s.gsub(/\n\s*/,'').should == data
  end

  it 'handles fragmented parsing' do
    process '<foo>', '<bar/>', '</foo>'
    client.data.size.should == 1
    client.data[0].to_s.gsub(/\n\s*/,'').should == '<foo><bar/></foo>'
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

  it 'handles attributes with entities properly' do
    check_parse '<a href="http://example.com?a=1&amp;b=2">example</a>'
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
          '<special-application-condition xmlns="special:application-ns"/>',
        "</error>",
      "</message>"
    ]
    process *data
    client.data.size.should == 1
    client.data[0].to_s.split("\n").map{|n|n.strip}.should == data
    client.data[0].xpath('//*[namespace-uri()="urn:ietf:params:xml:ns:xmpp-stanzas"]').size.should == 2
  end

  it 'handles not absolute namespaces' do
    lambda do
      process '<iq type="result" id="blather0007" to="n@d/r"><vCard xmlns="vcard-temp"/></iq>'
    end.should_not raise_error
  end

  it 'responds with stream:stream as a separate response' do
    process '<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="example.com" version="1.0">',
      '<foo/>'
    client.data.size.should == 2
    client.data[0].document.xpath('/stream:stream[@to="example.com" and @version="1.0"]', 'xmlns' => 'jabber:client', 'stream' => 'http://etherx.jabber.org/streams').size.should == 1
    client.data[1].to_s.should == '<foo/>'
  end

  it 'response with stream:end when receiving </stream:stream>' do
    process '<stream:stream xmlns:stream="http://etherx.jabber.org/streams"/>'
    client.data.size.should == 2
    client.data[1].to_s.should == '<stream:end xmlns:stream="http://etherx.jabber.org/streams"/>'
  end

  it 'raises ParseError when an error is sent' do
    lambda { process "<stream:stream>" }.should raise_error(Blather::ParseError)
  end

  it 'handles stream stanzas without an issue' do
    process '<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="example.com" version="1.0">',
      '<stream:features/>'
    client.data.size.should == 2
    client.data[0].document.xpath('/stream:stream[@to="example.com" and @version="1.0"]', 'xmlns' => 'jabber:client', 'stream' => 'http://etherx.jabber.org/streams').size.should == 1
    client.data[1].to_s.should == '<stream:features xmlns:stream="http://etherx.jabber.org/streams"/>'
  end

  it 'ignores the client namespace on stanzas' do
    process "<message type='chat' to='n@d' from='n@d/r' id='id1' xmlns='jabber:client'>",
      "<body>exit</body>",
      "<html xmlns='http://jabber.org/protocol/xhtml-im'><body xmlns='http://www.w3.org/1999/xhtml'>exit</body></html>",
      "</message>"
    client.data.size.should == 1
    client.data[0].document.xpath('/message/body[.="exit"]').should_not be_empty
    client.data[0].document.xpath('/message/im:html/xhtml:body[.="exit"]', 'im' => 'http://jabber.org/protocol/xhtml-im', 'xhtml' => 'http://www.w3.org/1999/xhtml').should_not be_empty
  end

  it 'ignores the component namespace on stanzas' do
    process "<message type='chat' to='n@d' from='n@d/r' id='id1' xmlns='jabber:component:accept'>",
      "<body>exit</body>",
      "<html xmlns='http://jabber.org/protocol/xhtml-im'><body xmlns='http://www.w3.org/1999/xhtml'>exit</body></html>",
      "</message>"
    client.data.size.should == 1
    client.data[0].document.xpath('/message/body[.="exit"]').should_not be_empty
    client.data[0].document.xpath('/message/im:html/xhtml:body[.="exit"]', 'im' => 'http://jabber.org/protocol/xhtml-im', 'xhtml' => 'http://www.w3.org/1999/xhtml').should_not be_empty
  end
end
