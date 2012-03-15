require 'spec_helper'

def ibb_open_xml
<<-XML
<iq from='romeo@montague.net/orchard'
    id='jn3h8g65'
    to='juliet@capulet.com/balcony'
    type='set'>
  <open xmlns='http://jabber.org/protocol/ibb'
        block-size='4096'
        sid='i781hf64'
        stanza='iq'/>
</iq>
XML
end

def ibb_data_xml
<<-XML
<iq from='romeo@montague.net/orchard'
    id='kr91n475'
    to='juliet@capulet.com/balcony'
    type='set'>
  <data xmlns='http://jabber.org/protocol/ibb' seq='0' sid='i781hf64'>
    qANQR1DBwU4DX7jmYZnncmUQB/9KuKBddzQH+tZ1ZywKK0yHKnq57kWq+RFtQdCJ
    WpdWpR0uQsuJe7+vh3NWn59/gTc5MDlX8dS9p0ovStmNcyLhxVgmqS8ZKhsblVeu
    IpQ0JgavABqibJolc3BKrVtVV1igKiX/N7Pi8RtY1K18toaMDhdEfhBRzO/XB0+P
    AQhYlRjNacGcslkhXqNjK5Va4tuOAPy2n1Q8UUrHbUd0g+xJ9Bm0G0LZXyvCWyKH
    kuNEHFQiLuCY6Iv0myq6iX6tjuHehZlFSh80b5BVV9tNLwNR5Eqz1klxMhoghJOA
  </data>
</iq>
XML
end

def ibb_close_xml
<<-XML
<iq from='romeo@montague.net/orchard'
    id='us71g45j'
    to='juliet@capulet.com/balcony'
    type='set'>
  <close xmlns='http://jabber.org/protocol/ibb' sid='i781hf64'/>
</iq>
XML
end

describe Blather::Stanza::Iq::Ibb::Open do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:open, 'http://jabber.org/protocol/ibb').should == Blather::Stanza::Iq::Ibb::Open
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse ibb_open_xml
    node.should be_instance_of Blather::Stanza::Iq::Ibb::Open
  end

  it 'has open node' do
    node = Blather::XMPPNode.parse ibb_open_xml
    node.open.should be_kind_of Nokogiri::XML::Element
  end

  it 'can get sid' do
    node = Blather::XMPPNode.parse ibb_open_xml
    node.sid.should == 'i781hf64'
  end

  it 'deleted open node on reply' do
    node = Blather::XMPPNode.parse ibb_open_xml
    reply = node.reply
    reply.open.should be_nil
  end
end

describe Blather::Stanza::Iq::Ibb::Data do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:data, 'http://jabber.org/protocol/ibb').should == Blather::Stanza::Iq::Ibb::Data
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse ibb_data_xml
    node.should be_instance_of Blather::Stanza::Iq::Ibb::Data
  end

  it 'has data node' do
    node = Blather::XMPPNode.parse ibb_data_xml
    node.data.should be_kind_of Nokogiri::XML::Element
  end

  it 'can get sid' do
    node = Blather::XMPPNode.parse ibb_data_xml
    node.sid.should == 'i781hf64'
  end

  it 'deleted data node on reply' do
    node = Blather::XMPPNode.parse ibb_data_xml
    reply = node.reply
    reply.data.should be_nil
  end
end

describe Blather::Stanza::Iq::Ibb::Close do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:close, 'http://jabber.org/protocol/ibb').should == Blather::Stanza::Iq::Ibb::Close
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse ibb_close_xml
    node.should be_instance_of Blather::Stanza::Iq::Ibb::Close
  end

  it 'has close node' do
    node = Blather::XMPPNode.parse ibb_close_xml
    node.close.should be_kind_of Nokogiri::XML::Element
  end

  it 'can get sid' do
    node = Blather::XMPPNode.parse ibb_close_xml
    node.sid.should == 'i781hf64'
  end

  it 'deleted close node on reply' do
    node = Blather::XMPPNode.parse ibb_close_xml
    reply = node.reply
    reply.close.should be_nil
  end
end
