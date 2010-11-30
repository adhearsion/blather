require File.expand_path "../../../../spec_helper", __FILE__

def si_xml
<<-XML
<iq type='set' id='offer1' to='juliet@capulet.com/balcony' from='romeo@montague.net/orchard'>
  <si xmlns='http://jabber.org/protocol/si'
      id='a0'
      mime-type='text/plain'
      profile='http://jabber.org/protocol/si/profile/file-transfer'>
    <file xmlns='http://jabber.org/protocol/si/profile/file-transfer'
          name='test.txt'
          size='1022'>
      <range/>
    </file>
    <feature xmlns='http://jabber.org/protocol/feature-neg'>
      <x xmlns='jabber:x:data' type='form'>
        <field var='stream-method' type='list-single'>
          <option><value>http://jabber.org/protocol/bytestreams</value></option>
          <option><value>http://jabber.org/protocol/ibb</value></option>
        </field>
      </x>
    </feature>
  </si>
</iq>
XML
end

describe Blather::Stanza::Iq::Si do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:si, 'http://jabber.org/protocol/si').must_equal Blather::Stanza::Iq::Si
  end

  it 'can be imported' do
    doc = parse_stanza si_xml
    node = Blather::XMPPNode.import(doc.root)
    node.must_be_instance_of Blather::Stanza::Iq::Si
    node.si.must_be_instance_of Blather::Stanza::Iq::Si::Si
  end

  it 'ensures a si node is present on create' do
    iq = Blather::Stanza::Iq::Si.new
    iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si').wont_be_empty
  end

  it 'ensures a si node exists when calling #si' do
    iq = Blather::Stanza::Iq::Si.new
    iq.si.remove
    iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si').must_be_empty

    iq.si.wont_be_nil
    iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si').wont_be_empty
  end

  it 'ensures a si node is replaced when calling #si=' do
    doc = parse_stanza si_xml
    iq = Blather::XMPPNode.import(doc.root)

    new_si = Blather::Stanza::Iq::Si::Si.new
    new_si.id = 'a1'

    iq.si = new_si

    iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si').size.must_equal 1
    iq.si.id.must_equal 'a1'
  end
end

describe Blather::Stanza::Iq::Si::Si do
  it 'can set and get attributes' do
    si = Blather::Stanza::Iq::Si::Si.new
    si.id = 'a1'
    si.mime_type = 'text/plain'
    si.profile = 'http://jabber.org/protocol/si/profile/file-transfer'
    si.id.must_equal 'a1'
    si.mime_type.must_equal 'text/plain'
    si.profile.must_equal 'http://jabber.org/protocol/si/profile/file-transfer'
  end
end

describe Blather::Stanza::Iq::Si::Si::File do
  it 'can be initialized with name and size' do
    file = Blather::Stanza::Iq::Si::Si::File.new('test.txt', 123)
    file.name.must_equal 'test.txt'
    file.size.must_equal 123
  end

  it 'can be initialized with node' do
    doc = parse_stanza si_xml
    node = Blather::XMPPNode.import(doc.root)

    file = Blather::Stanza::Iq::Si::Si::File.new node.find_first('.//ns:file', :ns => 'http://jabber.org/protocol/si/profile/file-transfer')
    file.name.must_equal 'test.txt'
    file.size.must_equal 1022
  end

  it 'can set and get description' do
    file = Blather::Stanza::Iq::Si::Si::File.new('test.txt', 123)
    file.desc = 'This is a test. If this were a real file...'
    file.desc.must_equal 'This is a test. If this were a real file...'
  end
end