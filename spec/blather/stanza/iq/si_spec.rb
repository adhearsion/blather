require 'spec_helper'

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
    expect(Blather::XMPPNode.class_from_registration(:si, 'http://jabber.org/protocol/si')).to eq(Blather::Stanza::Iq::Si)
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse si_xml
    expect(node).to be_instance_of Blather::Stanza::Iq::Si
    expect(node.si).to be_instance_of Blather::Stanza::Iq::Si::Si
  end

  it 'ensures a si node is present on create' do
    iq = Blather::Stanza::Iq::Si.new
    expect(iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si')).not_to be_empty
  end

  it 'ensures a si node exists when calling #si' do
    iq = Blather::Stanza::Iq::Si.new
    iq.si.remove
    expect(iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si')).to be_empty

    expect(iq.si).not_to be_nil
    expect(iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si')).not_to be_empty
  end

  it 'ensures a si node is replaced when calling #si=' do
    iq = Blather::XMPPNode.parse si_xml

    new_si = Blather::Stanza::Iq::Si::Si.new
    new_si.id = 'a1'

    iq.si = new_si

    expect(iq.xpath('ns:si', :ns => 'http://jabber.org/protocol/si').size).to eq(1)
    expect(iq.si.id).to eq('a1')
  end
end

describe Blather::Stanza::Iq::Si::Si do
  it 'can set and get attributes' do
    si = Blather::Stanza::Iq::Si::Si.new
    si.id = 'a1'
    si.mime_type = 'text/plain'
    si.profile = 'http://jabber.org/protocol/si/profile/file-transfer'
    expect(si.id).to eq('a1')
    expect(si.mime_type).to eq('text/plain')
    expect(si.profile).to eq('http://jabber.org/protocol/si/profile/file-transfer')
  end
end

describe Blather::Stanza::Iq::Si::Si::File do
  it 'can be initialized with name and size' do
    file = Blather::Stanza::Iq::Si::Si::File.new('test.txt', 123)
    expect(file.name).to eq('test.txt')
    expect(file.size).to eq(123)
  end

  it 'can be initialized with node' do
    node = Blather::XMPPNode.parse si_xml

    file = Blather::Stanza::Iq::Si::Si::File.new node.find_first('.//ns:file', :ns => 'http://jabber.org/protocol/si/profile/file-transfer')
    expect(file.name).to eq('test.txt')
    expect(file.size).to eq(1022)
  end

  it 'can set and get description' do
    file = Blather::Stanza::Iq::Si::Si::File.new('test.txt', 123)
    file.desc = 'This is a test. If this were a real file...'
    expect(file.desc).to eq('This is a test. If this were a real file...')
  end
end
