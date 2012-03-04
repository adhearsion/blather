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
    Blather::XMPPNode.class_from_registration(:ping, 'urn:xmpp:ping').should == Blather::Stanza::Iq::Ping
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse ping_xml
    node.should be_instance_of Blather::Stanza::Iq::Ping
  end

  it 'ensures a ping node is present on create' do
    iq = Blather::Stanza::Iq::Ping.new
    iq.xpath('ns:ping', :ns => 'urn:xmpp:ping').should_not be_empty
  end

  it 'ensures a ping node exists when calling #ping' do
    iq = Blather::Stanza::Iq::Ping.new
    iq.ping.remove
    iq.xpath('ns:ping', :ns => 'urn:xmpp:ping').should be_empty

    iq.ping.should_not be_nil
    iq.xpath('ns:ping', :ns => 'urn:xmpp:ping').should_not be_empty
  end

  it 'responds with an empty IQ' do
    ping = Blather::Stanza::Iq::Ping.new :get, 'one@example.com', 'abc123'
    ping.from = 'two@example.com'
    expected_pong = Blather::Stanza::Iq::Ping.new(:result, 'two@example.com', 'abc123').tap do |pong|
      pong.from = 'one@example.com'
    end
    reply = ping.reply
    reply.should == expected_pong
    reply.children.count.should == 0
  end
end
