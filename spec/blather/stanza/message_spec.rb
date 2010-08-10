require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

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
    </message>
  XML
end

describe Blather::Stanza::Message do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:message, nil).must_equal Blather::Stanza::Message
  end

  it 'must be importable' do
    Blather::XMPPNode.import(parse_stanza(message_xml).root).must_be_instance_of Blather::Stanza::Message
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
    h << (b = Blather::XMPPNode.new('body', msg.document))
    b.namespace = Blather::Stanza::Message::HTML_BODY_NS

    msg.xhtml_node.must_equal(b)
  end

  it 'has an xhtml setter' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml</some>"
    msg.xhtml = xhtml
    msg.xhtml_node.content.strip.must_equal(xhtml)
  end

  it 'sets valid xhtml even if the input is not valid' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml"
    msg.xhtml = xhtml
    msg.xhtml_node.content.strip.must_equal("<some>xhtml</some>")
  end

  it 'has an xhtml getter' do
    msg = Blather::Stanza::Message.new
    xhtml = "<some>xhtml</some>"
    msg.xhtml = xhtml
    msg.xhtml.must_equal(xhtml)
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
end