require 'spec_helper'

def s5b_open_xml
<<-XML
<iq from='requester@example.com/foo'
    id='hu3vax16'
    to='target@example.org/bar'
    type='set'>
  <query xmlns='http://jabber.org/protocol/bytestreams'
         sid='vxf9n471bn46'>
    <streamhost
        jid='requester@example.com/foo'
        host='192.168.4.1'
        port='5086'/>
    <streamhost
        jid='requester2@example.com/foo'
        host='192.168.4.2'
        port='5087'/>
  </query>
</iq>
XML
end

describe Blather::Stanza::Iq::S5b do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/bytestreams')).to eq(Blather::Stanza::Iq::S5b)
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse s5b_open_xml
    expect(node).to be_instance_of Blather::Stanza::Iq::S5b
  end

  it 'can get sid' do
    node = Blather::XMPPNode.parse s5b_open_xml
    expect(node.sid).to eq('vxf9n471bn46')
  end

  it 'can get streamhosts' do
    node = Blather::XMPPNode.parse s5b_open_xml
    expect(node.streamhosts.size).to eq(2)
  end

  it 'can set streamhosts' do
    node = Blather::Stanza::Iq::S5b.new
    node.streamhosts += [{:jid => 'test@example.com/foo', :host => '192.168.5.1', :port => 123}]
    expect(node.streamhosts.size).to eq(1)
    node.streamhosts += [Blather::Stanza::Iq::S5b::StreamHost.new('test2@example.com/foo', '192.168.5.2', 123)]
    expect(node.streamhosts.size).to eq(2)
  end

  it 'can get and set streamhost-used' do
    node = Blather::Stanza::Iq::S5b.new
    node.streamhost_used = 'used@example.com/foo'
    expect(node.streamhost_used.jid.to_s).to eq('used@example.com/foo')
  end
end
