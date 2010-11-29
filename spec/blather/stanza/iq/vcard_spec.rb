require File.expand_path "../../../../spec_helper", __FILE__

def vcard_xml
<<-XML
  <iq type="result" id="blather0007" to="romeo@example.net">
    <vCard xmlns="vcard-temp">
      <NICKNAME>Romeo</NICKNAME>
    </vCard>
  </iq>
XML
end

describe Blather::Stanza::Iq::Vcard do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:vCard, 'vcard-temp').must_equal Blather::Stanza::Iq::Vcard
  end

  it 'can be imported' do
    doc = parse_stanza vcard_xml
    query = Blather::XMPPNode.import(doc.root)
    query.must_be_instance_of Blather::Stanza::Iq::Vcard
    query.vcard.must_be_instance_of Blather::Stanza::Iq::Vcard::Vcard
  end

  it 'ensures a vcard node is present on create' do
    query = Blather::Stanza::Iq::Vcard.new
    query.xpath('ns:vCard', :ns => 'vcard-temp').wont_be_empty
  end

  it 'ensures a vcard node exists when calling #vcard' do
    query = Blather::Stanza::Iq::Vcard.new
    query.vcard.remove
    query.xpath('ns:vCard', :ns => 'vcard-temp').must_be_empty

    query.vcard.wont_be_nil
    query.xpath('ns:vCard', :ns => 'vcard-temp').wont_be_empty
  end

  it 'ensures a vcard node is replaced when calling #vcard=' do
    doc = parse_stanza vcard_xml
    query = Blather::XMPPNode.import(doc.root)

    new_vcard = Blather::Stanza::Iq::Vcard::Vcard.new
    new_vcard["NICKNAME"] = 'Mercutio'

    query.vcard = new_vcard
    
    query.xpath('ns:vCard', :ns => 'vcard-temp').size.must_equal 1
    query.find_first('ns:vCard/ns:NICKNAME', :ns => 'vcard-temp').content.must_equal 'Mercutio'
  end
end

describe Blather::Stanza::Iq::Vcard::Vcard do
  it 'can set vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    query.find_first('ns:vCard/ns:NICKNAME', :ns => 'vcard-temp').content.must_equal 'Romeo'
  end

  it 'can set deep vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['PHOTO/TYPE'] = 'image/png'
    query.vcard['PHOTO/BINVAL'] = '===='
    query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.size.must_equal 2
    query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.detect { |n| n.element_name == 'TYPE' && n.content == 'image/png' }.wont_be_nil
    query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.detect { |n| n.element_name == 'BINVAL' && n.content == '====' }.wont_be_nil
  end

  it 'can get vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    query.vcard['NICKNAME'].must_equal 'Romeo'
  end

  it 'can get deep vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['PHOTO/TYPE'] = 'image/png'
    query.vcard['PHOTO/BINVAL'] = '===='
    query.vcard['PHOTO/TYPE'].must_equal 'image/png'
    query.vcard['PHOTO/BINVAL'].must_equal '===='
  end

  it 'returns nil on vcard elements which does not exist' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    query.vcard['FN'].must_be_nil
  end

  it 'can update vcard elements' do
    doc = parse_stanza vcard_xml
    query = Blather::XMPPNode.import(doc.root)
    query.vcard['NICKNAME'].must_equal 'Romeo'
    query.vcard['NICKNAME'] = 'Mercutio'
    query.vcard['NICKNAME'].must_equal 'Mercutio'
  end
end