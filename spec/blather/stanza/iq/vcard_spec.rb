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
    Blather::XMPPNode.class_from_registration(:vCard, 'vcard-temp').should == Blather::Stanza::Iq::Vcard
  end

  it 'can be imported' do
    query = Blather::XMPPNode.parse vcard_xml
    query.should be_instance_of Blather::Stanza::Iq::Vcard
    query.vcard.should be_instance_of Blather::Stanza::Iq::Vcard::Vcard
  end

  it 'ensures a vcard node is present on create' do
    query = Blather::Stanza::Iq::Vcard.new
    query.xpath('ns:vCard', :ns => 'vcard-temp').should_not be_empty
  end

  it 'ensures a vcard node exists when calling #vcard' do
    query = Blather::Stanza::Iq::Vcard.new
    query.vcard.remove
    query.xpath('ns:vCard', :ns => 'vcard-temp').should be_empty

    query.vcard.should_not be_nil
    query.xpath('ns:vCard', :ns => 'vcard-temp').should_not be_empty
  end

  it 'ensures a vcard node is replaced when calling #vcard=' do
    query = Blather::XMPPNode.parse vcard_xml

    new_vcard = Blather::Stanza::Iq::Vcard::Vcard.new
    new_vcard["NICKNAME"] = 'Mercutio'

    query.vcard = new_vcard

    query.xpath('ns:vCard', :ns => 'vcard-temp').size.should == 1
    query.find_first('ns:vCard/ns:NICKNAME', :ns => 'vcard-temp').content.should == 'Mercutio'
  end
end

describe Blather::Stanza::Iq::Vcard::Vcard do
  it 'can set vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    query.find_first('ns:vCard/ns:NICKNAME', :ns => 'vcard-temp').content.should == 'Romeo'
  end

  it 'can set deep vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['PHOTO/TYPE'] = 'image/png'
    query.vcard['PHOTO/BINVAL'] = '===='
    query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.size.should == 2
    query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.detect { |n| n.element_name == 'TYPE' && n.content == 'image/png' }.should_not be_nil
    query.find_first('ns:vCard/ns:PHOTO', :ns => 'vcard-temp').children.detect { |n| n.element_name == 'BINVAL' && n.content == '====' }.should_not be_nil
  end

  it 'can get vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    query.vcard['NICKNAME'].should == 'Romeo'
  end

  it 'can get deep vcard elements' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['PHOTO/TYPE'] = 'image/png'
    query.vcard['PHOTO/BINVAL'] = '===='
    query.vcard['PHOTO/TYPE'].should == 'image/png'
    query.vcard['PHOTO/BINVAL'].should == '===='
  end

  it 'returns nil on vcard elements which does not exist' do
    query = Blather::Stanza::Iq::Vcard.new :set
    query.vcard['NICKNAME'] = 'Romeo'
    query.vcard['FN'].should be_nil
  end

  it 'can update vcard elements' do
    query = Blather::XMPPNode.parse vcard_xml
    query.vcard['NICKNAME'].should == 'Romeo'
    query.vcard['NICKNAME'] = 'Mercutio'
    query.vcard['NICKNAME'].should == 'Mercutio'
  end
end
