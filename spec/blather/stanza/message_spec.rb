require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe Blather::Stanza::Message do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:message, nil).must_equal Blather::Stanza::Message
  end

  it 'must be importable' do
    doc = parse_stanza <<-XML
      <message
          to='romeo@example.net'
          from='juliet@example.com/balcony'
          type='chat'
          xml:lang='en'>
        <body>Wherefore art thou, Romeo?</body>
      </message>
    XML
    Blather::XMPPNode.import(doc.root).must_be_instance_of Blather::Stanza::Message
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
end
