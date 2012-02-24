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
    Blather::XMPPNode.class_from_registration(:message, nil).must_equal Blather::Stanza::Message
  end

  it 'must be importable' do
    Blather::XMPPNode.import(parse_stanza(message_xml).root).must_be_instance_of Blather::Stanza::Message
    Blather::XMPPNode.import(parse_stanza(ichat_message_xml).root).must_be_instance_of Blather::Stanza::Message
  end

  it 'provides "attr_accessor" for body' do
    s = Blather::Stanza::Message.new
    s.body.must_be_nil
    s.find('body').must_be_empty

    s.body = 'test message'
    s.body.wont_be_nil
    s.find('body').wont_be_empty
  end

  it 'provides "attr_accessor" for subject' do
    s = Blather::Stanza::Message.new
    s.subject.must_be_nil
    s.find('subject').must_be_empty

    s.subject = 'test subject'
    s.subject.wont_be_nil
    s.find('subject').wont_be_empty
  end

  it 'provides "attr_accessor" for thread' do
    s = Blather::Stanza::Message.new
    s.thread.must_be_nil
    s.find('thread').must_be_empty

    s.thread = 1234
    s.thread.wont_be_nil
    s.find('thread').wont_be_empty
  end

  it 'can set a parent attribute for thread' do
    s = Blather::Stanza::Message.new
    s.thread.must_be_nil
    s.find('thread').must_be_empty

    s.thread = {4321 => 1234}
    s.thread.must_equal '1234'
    s.parent_thread.must_equal '4321'
    s.find('thread[@parent="4321"]').wont_be_empty
  end

  it 'ensures type is one of Blather::Stanza::Message::VALID_TYPES' do
    lambda { Blather::Stanza::Message.new nil, nil, :invalid_type_name }.must_raise(Blather::ArgumentError)

    Blather::Stanza::Message::VALID_TYPES.each do |valid_type|
      msg = Blather::Stanza::Message.new nil, nil, valid_type
      msg.type.must_equal valid_type
    end
  end

  Blather::Stanza::Message::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Blather::Stanza::Message.new.must_respond_to :"#{valid_type}?"
    end
  end

  it 'ensures an html node exists when asked for xhtml_node' do
    search_args = [
      '/message/html_ns:html',
      {:html_ns => Blather::Stanza::Message::HTML_NS}
    ]
    msg = Blather::Stanza::Message.new
    msg.find_first(*search_args).must_be_nil

    msg.xhtml_node
    msg.find_first(*search_args).wont_be_nil
  end

  it 'ensures a body node exists when asked for xhtml_node' do
    search_args = [
      '/message/html_ns:html/body_ns:body',
      {:html_ns => Blather::Stanza::Message::HTML_NS,
      :body_ns => Blather::Stanza::Message::HTML_BODY_NS}
    ]
    msg = Blather::Stanza::Message.new
    msg.find_first(*search_args).must_be_nil

    msg.xhtml_node
    msg.find_first(*search_args).wont_be_nil
  end

  it 'returns an existing node when asked for xhtml_node' do
    msg = Blather::Stanza::Message.new
    msg << (h = Blather::XMPPNode.new('html', msg.document))
    h.namespace = Blather::Stanza::Message::HTML_NS
    b = Blather::XMPPNode.new('body', msg.document)
    b.namespace = Blather::Stanza::Message::HTML_BODY_NS
    h << b

    msg.xhtml_node.must_equal(b)
  end

  it 'has an xhtml setter' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml</some>"
    msg.xhtml = xhtml
    msg.xhtml_node.inner_html.strip.must_equal(xhtml)
  end

  it 'sets valid xhtml even if the input is not valid' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml"
    msg.xhtml = xhtml
    msg.xhtml_node.inner_html.strip.must_equal("<some>xhtml</some>")
  end

  it 'sets xhtml with more than one root node' do
    msg = Blather::Stanza::Message.new
    xhtml = "<i>xhtml</i> more xhtml"
    msg.xhtml = xhtml
    msg.xhtml_node.inner_html.strip.must_equal("<i>xhtml</i> more xhtml")
  end

  it 'has an xhtml getter' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml</some>"
    msg.xhtml = xhtml
    msg.xhtml.must_equal(xhtml)
  end

  it 'finds xhtml body when html wrapper has wrong namespace' do
    msg = Blather::XMPPNode.import(parse_stanza(ichat_message_xml).root)
    msg.xhtml.must_equal "<span style=\"font-family: 'Arial';font-size: 12px;color: #262626;\">Hello</span>\n  <img alt=\"f5ad3a04d218d7160fa02415e02d41b3.jpg\" src=\"message-attachments:1\" width=\"30\" height=\"30\"></img>"
  end

  it 'has a chat state setter' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = :composing
    msg.xpath('ns:composing', :ns => Blather::Stanza::Message::CHAT_STATE_NS).wont_be_empty
  end

  it 'will only add one chat state at a time' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = :composing
    msg.chat_state = :paused

    msg.xpath('ns:*', :ns => Blather::Stanza::Message::CHAT_STATE_NS).size.must_equal(1)
  end

  it 'ensures chat state setter accepts strings' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = "gone"
    msg.xpath('ns:gone', :ns => Blather::Stanza::Message::CHAT_STATE_NS).wont_be_empty
  end

  it 'ensures chat state is one of Blather::Stanza::Message::VALID_CHAT_STATES' do
    lambda do
      msg = Blather::Stanza::Message.new
      msg.chat_state = :invalid_chat_state
    end.must_raise(Blather::ArgumentError)

    Blather::Stanza::Message::VALID_CHAT_STATES.each do |valid_chat_state|
      msg = Blather::Stanza::Message.new
      msg.chat_state = valid_chat_state
      msg.chat_state.must_equal valid_chat_state
    end
  end

  it 'has a chat state getter' do
    msg = Blather::Stanza::Message.new
    msg.chat_state = :paused
    msg.chat_state.must_equal(:paused)
  end

  it 'imports correct chat state' do
    Blather::XMPPNode.import(parse_stanza(message_xml).root).chat_state.must_equal :paused
  end

  it 'makes a form child available' do
    n = Blather::XMPPNode.import(parse_stanza(message_xml).root)
    n.form.fields.size.must_equal 1
    n.form.fields.map { |f| f.class }.uniq.must_equal [Blather::Stanza::X::Field]
    n.form.must_be_instance_of Blather::Stanza::X

    r = Blather::Stanza::Message.new
    r.form.type = :form
    r.form.type.must_equal :form
  end

  it 'ensures the form child is a direct child' do
    r = Blather::Stanza::Message.new
    r.form
    r.xpath('ns:x', :ns => Blather::Stanza::X.registered_ns).wont_be_empty
  end

  it 'is not delayed' do
    n = Blather::XMPPNode.import(parse_stanza(message_xml).root)
    n.delay.must_equal nil
    n.delayed?.must_equal false
  end

  describe "with a delay" do
    it "is delayed" do
      n = Blather::XMPPNode.import(parse_stanza(delayed_message_xml).root)
      n.delayed?.must_equal true
      n.delay.must_be_instance_of Blather::Stanza::Message::Delay
      n.delay.from.must_equal 'coven@chat.shakespeare.lit'
      n.delay.stamp.must_equal Time.new(2002, 10, 13, 23, 58, 37, 0)
      n.delay.description.must_equal "Too slow"
    end
  end
end
