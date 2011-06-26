require 'spec_helper'

def ping_xml
<<-XML
<iq from='capulet.lit' to='juliet@capulet.lit/balcony' id='s2c1' type='get'>
  <ping xmlns='urn:xmpp:ping'/>
</iq>
XML
end

describe Blather::Stanza::Iq::Ping do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:ping, 'urn:xmpp:ping').must_equal Blather::Stanza::Iq::Ping
  end

  it 'can be imported' do
    doc = parse_stanza ping_xml
    node = Blather::XMPPNode.import(doc.root)
    node.must_be_instance_of Blather::Stanza::Iq::Ping
  end

  it 'ensures a ping node is present on create' do
    iq = Blather::Stanza::Iq::Ping.new
    iq.xpath('ns:ping', :ns => 'urn:xmpp:ping').wont_be_empty
  end

  it 'ensures a ping node exists when calling #ping' do
    iq = Blather::Stanza::Iq::Ping.new
    iq.ping.remove
    iq.xpath('ns:ping', :ns => 'urn:xmpp:ping').must_be_empty

    iq.ping.wont_be_nil
    iq.xpath('ns:ping', :ns => 'urn:xmpp:ping').wont_be_empty
  end

  it 'responds with an empty IQ' do
    ping = Blather::Stanza::Iq::Ping.new :get, 'one@example.com', 'abc123'
    ping.from = 'two@example.com'
    ping.reply.must_equal Blather::Stanza::Iq.new(:result, 'two@example.com', 'abc123')
  end
end
