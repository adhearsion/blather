require 'spec_helper'

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
    expect(Blather::XMPPNode.class_from_registration(:vCard, 'vcard-temp')).to eq(Blather::Stanza::Iq::Vcard)
  end

  it 'can be imported' do
    query = Blather::XMPPNode.parse vcard_xml
    expect(query).to be_instance_of Blather::Stanza::Iq::Vcard
    expect(query.vcard).to be_instance_of Blather::Stanza::Iq::Vcard::Vcard
  end

  it 'ensures a vcard node is present on create' do
    query = Blather::Stanza::Iq::Vcard.new
    expect(query.xpath('ns:vCard', :ns => 'vcard-temp')).not_to be_empty
  end

  it 'ensures a vcard node exists when calling #vcard' do
    query = Blather::Stanza::Iq::Vcard.new
    query.vcard.remove
    expect(query.xpath('ns:vCard', :ns => 'vcard-temp')).to be_empty

    expect(query.vcard).not_to be_nil
    expect(query.xpath('ns:vCard', :ns => 'vcard-temp')).not_to be_empty
  end

  it 'ensures a vcard node is replaced when calling #vcard=' do
    query = Blather::XMPPNode.parse vcard_xml

    new_vcard = Blather::Stanza::Iq::Vcard::Vcard.new
    new_vcard["NICKNAME"] = 'Mercutio'

    query.vcard = new_vcard

    expect(query.xpath('ns:vCard', :ns => 'vcard-temp').size).to eq(1)
    expect(query.find_first('ns:vCard/ns:NICKNAME', :ns => 'vcard-temp').content).to eq('Mercutio')
  end
end

describe Blather::Stanza::Iq::Vcard::Vcard do
  it 'can set vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    expect(query.find_first('ns:vCard/ns:NICKNAME', :ns => 'vcard-temp').content).to eq('Romeo')
  end

  it 'can set deep vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['PHOTO/TYPE'] = 'image/png'
    query.vcard['PHOTO/BINVAL'] = '===='
    expect(query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.size).to eq(2)
    expect(query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.detect { |n| n.element_name == 'TYPE' && n.content == 'image/png' }).not_to be_nil
    expect(query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.detect { |n| n.element_name == 'BINVAL' && n.content == '====' }).not_to be_nil
  end

  it 'can get vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    expect(query.vcard['NICKNAME']).to eq('Romeo')
  end

  it 'can get deep vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['PHOTO/TYPE'] = 'image/png'
    query.vcard['PHOTO/BINVAL'] = '===='
    expect(query.vcard['PHOTO/TYPE']).to eq('image/png')
    expect(query.vcard['PHOTO/BINVAL']).to eq('====')
  end

  it 'returns nil on vcard elements which does not exist' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    expect(query.vcard['FN']).to be_nil
  end

  it 'can update vcard elements' do
    query = Blather::XMPPNode.parse vcard_xml
    expect(query.vcard['NICKNAME']).to eq('Romeo')
    query.vcard['NICKNAME'] = 'Mercutio'
    expect(query.vcard['NICKNAME']).to eq('Mercutio')
  end
end
