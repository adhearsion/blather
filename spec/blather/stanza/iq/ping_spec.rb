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
    expect(Blather::XMPPNode.class_from_registration(:ping, 'urn:xmpp:ping')).to eq(Blather::Stanza::Iq::Ping)
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse ping_xml
    expect(node).to be_instance_of Blather::Stanza::Iq::Ping
  end

  it 'ensures a ping node is present on create' do
    iq = Blather::Stanza::Iq::Ping.new
    expect(iq.xpath('ns:ping', :ns => 'urn:xmpp:ping')).not_to be_empty
  end

  it 'ensures a ping node exists when calling #ping' do
    iq = Blather::Stanza::Iq::Ping.new
    iq.ping.remove
    expect(iq.xpath('ns:ping', :ns => 'urn:xmpp:ping')).to be_empty

    expect(iq.ping).not_to be_nil
    expect(iq.xpath('ns:ping', :ns => 'urn:xmpp:ping')).not_to be_empty
  end

  it 'responds with an empty IQ' do
    ping = Blather::Stanza::Iq::Ping.new :get, 'one@example.com', 'abc123'
    ping.from = 'two@example.com'
    expected_pong = Blather::Stanza::Iq::Ping.new(:result, 'two@example.com', 'abc123').tap do |pong|
      pong.from = 'one@example.com'
    end
    reply = ping.reply
    expect(reply).to eq(expected_pong)
    expect(reply.children.count).to eq(0)
  end
end
