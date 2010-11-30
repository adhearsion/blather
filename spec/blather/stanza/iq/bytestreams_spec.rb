require File.expand_path "../../../../spec_helper", __FILE__

def bytestreams_open_xml
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

describe Blather::Stanza::Iq::Bytestreams do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/bytestreams').must_equal Blather::Stanza::Iq::Bytestreams
  end

  it 'can be imported' do
    doc = parse_stanza bytestreams_open_xml
    node = Blather::XMPPNode.import(doc.root)
    node.must_be_instance_of Blather::Stanza::Iq::Bytestreams
  end

  it 'can get sid' do
    doc = parse_stanza bytestreams_open_xml
    node = Blather::XMPPNode.import(doc.root)
    node.sid.must_equal 'vxf9n471bn46'
  end

  it 'can get streamhosts' do
    doc = parse_stanza bytestreams_open_xml
    node = Blather::XMPPNode.import(doc.root)
    node.streamhosts.size.must_equal 2
  end

  it 'can set streamhosts' do
    node = Blather::Stanza::Iq::Bytestreams.new
    node.streamhosts += [{:jid => 'test@example.com/foo', :host => '192.168.5.1', :port => 123}]
    node.streamhosts.size.must_equal 1
    node.streamhosts += [Blather::Stanza::Iq::Bytestreams::StreamHost.new('test2@example.com/foo', '192.168.5.2', 123)]
    node.streamhosts.size.must_equal 2
  end

  it 'can get and set streamhost-used' do
    node = Blather::Stanza::Iq::Bytestreams.new
    node.streamhost_used = 'used@example.com/foo'
    node.streamhost_used.jid.to_s.must_equal 'used@example.com/foo'
  end
end