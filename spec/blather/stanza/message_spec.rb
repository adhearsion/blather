require 'spec_helper'

def ichat_message_xml
  <<-XML
  <message from="juliet@example.com/balcony" to="romeo@example.net" type="chat" id="iChat_5FA6C6DC">
  <body>Hello</body>
  <html xmlns="http://www.w3.org/1999/xhtml">
  <body style="background-color:#7bb5ee;color:#000000;">
  <span style="font-family: 'Arial';font-size: 12px;color: #262626;">Hello</span>
  <img alt="f5ad3a04d218d7160fa02415e02d41b3.jpg" src="message-attachments:1" width="30" height="30"/>
  </body>
  </html>

  <x xmlns="http://www.apple.com/xmpp/message-attachments">
  <attachment id="1">
  <sipub xmlns="http://jabber.org/protocol/sipub" from="juliet@example.com/balcony" id="sipubid_77933F62" mime-type="binary/octet-stream" profile="http://jabber.org/protocol/si/profile/file-transfer">
  <file xmlns="http://jabber.org/protocol/si/profile/file-transfer" xmlns:ichat="apple:profile:transfer-extensions" name="f5ad3a04d218d7160fa02415e02d41b3.jpg" size="1245" posixflags="000001A4"/>
  </sipub>
  </attachment>
  </x>

  <iq type="set" id="iChat_4CC32F1F" to="romeo@example.net">
  <si xmlns="http://jabber.org/protocol/si" id="sid_60C2D273" mime-type="binary/octet-stream" profile="http://jabber.org/protocol/si/profile/file-transfer">
  <file xmlns="http://jabber.org/protocol/si/profile/file-transfer" xmlns:ichat="apple:profile:transfer-extensions" name="f5ad3a04d218d7160fa02415e02d41b3.jpg" size="1245" posixflags="000001A4"/>
  <feature xmlns="http://jabber.org/protocol/feature-neg">
  <x xmlns="jabber:x:data" type="form">
  <field type="list-single" var="stream-method">
  <option><value>http://jabber.org/protocol/bytestreams</value></option>
  </field>
  </x>
  </feature>
  </si>
  </iq>
  </message>
  XML
end

def message_xml
  <<-XML
    <message
        to='romeo@example.net'
        from='juliet@example.com/balcony'
        type='chat'
        xml:lang='en'>
      <body>Wherefore art thou, Romeo?</body>
      <x xmlns='jabber:x:data' type='form'>
        <field var='field-name' type='text-single' label='description' />
      </x>
      <paused xmlns="http://jabber.org/protocol/chatstates"/>
    </message>
  XML
end

def delayed_message_xml
  <<-XML
    <message
        from='coven@chat.shakespeare.lit/firstwitch'
        id='162BEBB1-F6DB-4D9A-9BD8-CFDCC801A0B2'
        to='hecate@shakespeare.lit/broom'
        type='groupchat'>
      <body>Thrice the brinded cat hath mew'd.</body>
      <delay xmlns='urn:xmpp:delay'
         from='coven@chat.shakespeare.lit'
         stamp='2002-10-13T23:58:37Z'>
        Too slow
      </delay>
    </message>
  XML
end

describe Blather::Stanza::Message do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:message, nil)).to eq(Blather::Stanza::Message)
  end

  it 'must be importable' do
    expect(Blather::XMPPNode.parse(message_xml)).to be_instance_of Blather::Stanza::Message
    expect(Blather::XMPPNode.parse(ichat_message_xml)).to be_instance_of Blather::Stanza::Message
  end

  it 'provides "attr_accessor" for body' do
    s = Blather::Stanza::Message.new
    expect(s.body).to be_nil
    expect(s.find('body')).to be_empty

    s.body = 'test message'
    expect(s.body).not_to be_nil
    expect(s.find('body')).not_to be_empty
  end

  it 'provides "attr_accessor" for subject' do
    s = Blather::Stanza::Message.new
    expect(s.subject).to be_nil
    expect(s.find('subject')).to be_empty

    s.subject = 'test subject'
    expect(s.subject).not_to be_nil
    expect(s.find('subject')).not_to be_empty
  end

  it 'provides "attr_accessor" for thread' do
    s = Blather::Stanza::Message.new
    expect(s.thread).to be_nil
    expect(s.find('thread')).to be_empty

    s.thread = 1234
    expect(s.thread).not_to be_nil
    expect(s.find('thread')).not_to be_empty
  end

  it 'can set a parent attribute for thread' do
    s = Blather::Stanza::Message.new
    expect(s.thread).to be_nil
    expect(s.find('thread')).to be_empty

    s.thread = {4321 => 1234}
    expect(s.thread).to eq('1234')
    expect(s.parent_thread).to eq('4321')
    expect(s.find('thread[@parent="4321"]')).not_to be_empty
  end

  it 'ensures type is one of Blather::Stanza::Message::VALID_TYPES' do
    expect { Blather::Stanza::Message.new nil, nil, :invalid_type_name }.to raise_error(Blather::ArgumentError)

    Blather::Stanza::Message::VALID_TYPES.each do |valid_type|
      msg = Blather::Stanza::Message.new nil, nil, valid_type
      expect(msg.type).to eq(valid_type)
    end
  end

  Blather::Stanza::Message::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      expect(Blather::Stanza::Message.new).to respond_to :"#{valid_type}?"
    end
  end

  it 'ensures an html node exists when asked for xhtml_node' do
    search_args = [
      '/message/html_ns:html',
      {:html_ns => Blather::Stanza::Message::HTML_NS}
    ]
    msg = Blather::Stanza::Message.new
    expect(msg.find_first(*search_args)).to be_nil

    msg.xhtml_node
    expect(msg.find_first(*search_args)).not_to be_nil
  end

  it 'ensures a body node exists when asked for xhtml_node' do
    search_args = [
      '/message/html_ns:html/body_ns:body',
      {:html_ns => Blather::Stanza::Message::HTML_NS,
      :body_ns => Blather::Stanza::Message::HTML_BODY_NS}
    ]
    msg = Blather::Stanza::Message.new
    expect(msg.find_first(*search_args)).to be_nil

    msg.xhtml_node
    expect(msg.find_first(*search_args)).not_to be_nil
  end

  it 'returns an existing node when asked for xhtml_node' do
    msg = Blather::Stanza::Message.new
    msg << (h = Blather::XMPPNode.new('html', msg.document))
    h.namespace = Blather::Stanza::Message::HTML_NS
    b = Blather::XMPPNode.new('body', msg.document)
    b.namespace = Blather::Stanza::Message::HTML_BODY_NS
    h << b

    expect(msg.xhtml_node).to eq(b)
  end

  it 'has an xhtml setter' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml</some>"
    msg.xhtml = xhtml
    expect(msg.xhtml_node.inner_html.strip).to eq(xhtml)
  end

  it 'sets valid xhtml even if the input is not valid' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml"
    msg.xhtml = xhtml
    expect(msg.xhtml_node.inner_html.strip).to eq("<some>xhtml</some>")
  end

  it 'sets xhtml with more than one root node' do
    msg = Blather::Stanza::Message.new
    xhtml = "<i>xhtml</i> more xhtml"
    msg.xhtml = xhtml
    expect(msg.xhtml_node.inner_html.strip).to eq("<i>xhtml</i> more xhtml")
  end

  it 'has an xhtml getter' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml</some>"
    msg.xhtml = xhtml
    expect(msg.xhtml).to eq(xhtml)
  end

  it 'finds xhtml body when html wrapper has wrong namespace' do
    msg = Blather::XMPPNode.parse(ichat_message_xml)
    expect(Nokogiri::XML(msg.xhtml).to_xml).to eq(Nokogiri::XML("<span style=\"font-family: 'Arial';font-size: 12px;color: #262626;\">Hello</span>\n  <img alt=\"f5ad3a04d218d7160fa02415e02d41b3.jpg\" src=\"message-attachments:1\" width=\"30\" height=\"30\"></img>").to_xml)
  end

  it 'has a chat state setter' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = :composing
    expect(msg.xpath('ns:composing', :ns => Blather::Stanza::Message::CHAT_STATE_NS)).not_to be_empty
  end

  it 'will only add one chat state at a time' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = :composing
    msg.chat_state = :paused

    expect(msg.xpath('ns:*', :ns => Blather::Stanza::Message::CHAT_STATE_NS).size).to eq(1)
  end

  it 'ensures chat state setter accepts strings' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = "gone"
    expect(msg.xpath('ns:gone', :ns => Blather::Stanza::Message::CHAT_STATE_NS)).not_to be_empty
  end

  it 'ensures chat state is one of Blather::Stanza::Message::VALID_CHAT_STATES' do
    expect do
      msg = Blather::Stanza::Message.new
      msg.chat_state = :invalid_chat_state
    end.to raise_error(Blather::ArgumentError)

    Blather::Stanza::Message::VALID_CHAT_STATES.each do |valid_chat_state|
      msg = Blather::Stanza::Message.new
      msg.chat_state = valid_chat_state
      expect(msg.chat_state).to eq(valid_chat_state)
    end
  end

  it 'has a chat state getter' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = :paused
    expect(msg.chat_state).to eq(:paused)
  end

  it 'imports correct chat state' do
    expect(Blather::XMPPNode.parse(message_xml).chat_state).to eq(:paused)
  end

  it 'makes a form child available' do
    n = Blather::XMPPNode.parse(message_xml)
    expect(n.form.fields.size).to eq(1)
    expect(n.form.fields.map { |f| f.class }.uniq).to eq([Blather::Stanza::X::Field])
    expect(n.form).to be_instance_of Blather::Stanza::X

    r = Blather::Stanza::Message.new
    r.form.type = :form
    expect(r.form.type).to eq(:form)
  end

  it 'ensures the form child is a direct child' do
    r = Blather::Stanza::Message.new
    r.form
    expect(r.xpath('ns:x', :ns => Blather::Stanza::X.registered_ns)).not_to be_empty
  end

  it 'is not delayed' do
    n = Blather::XMPPNode.parse(message_xml)
    expect(n.delay).to eq(nil)
    expect(n.delayed?).to eq(false)
  end

  describe "with a delay" do
    it "is delayed" do
      n = Blather::XMPPNode.parse(delayed_message_xml)
      expect(n.delayed?).to eq(true)
      expect(n.delay).to be_instance_of Blather::Stanza::Message::Delay
      expect(n.delay.from).to eq('coven@chat.shakespeare.lit')
      expect(n.delay.stamp).to eq(Time.utc(2002, 10, 13, 23, 58, 37, 0))
      expect(n.delay.description).to eq("Too slow")
    end
  end
end
