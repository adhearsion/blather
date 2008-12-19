require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::Message' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:message, nil).must_equal Stanza::Message
  end

  it 'provides "attr_accessor" for body' do
    s = Stanza::Message.new
    s.body.must_be_nil
    s.detect { |n| n.element_name == 'body' }.must_be_nil

    s.body = 'test message'
    s.body.wont_be_nil
    s.detect { |n| n.element_name == 'body' }.wont_be_nil
  end

  it 'provides "attr_accessor" for subject' do
    s = Stanza::Message.new
    s.subject.must_be_nil
    s.detect { |n| n.element_name == 'subject' }.must_be_nil

    s.subject = 'test subject'
    s.subject.wont_be_nil
    s.detect { |n| n.element_name == 'subject' }.wont_be_nil
  end

  it 'provides "attr_accessor" for thread' do
    s = Stanza::Message.new
    s.thread.must_be_nil
    s.detect { |n| n.element_name == 'thread' }.must_be_nil

    s.thread = 1234
    s.thread.wont_be_nil
    s.detect { |n| n.element_name == 'thread' }.wont_be_nil
  end

  it 'ensures type is one of Stanza::Message::VALID_TYPES' do
    lambda { Stanza::Message.new nil, nil, :invalid_type_name }.must_raise(Blather::ArgumentError)

    Stanza::Message::VALID_TYPES.each do |valid_type|
      msg = Stanza::Message.new nil, nil, valid_type
      msg.type.must_equal valid_type
    end
  end

  Stanza::Message::VALID_TYPES.each do |valid_type|
    it "provides a helper (#{valid_type}?) for type #{valid_type}" do
      Stanza::Message.new.must_respond_to :"#{valid_type}?"
    end
  end
end
