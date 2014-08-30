require 'spec_helper'

def stream_error_node(error = 'internal-server-error', msg = nil)
  node = Blather::XMPPNode.new('error')
  node.namespace = {'stream' => Blather::Stream::STREAM_NS}

  node << (err = Blather::XMPPNode.new(error, node.document))
  err.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'

  if msg
    node << (text = Blather::XMPPNode.new('text', node.document))
    text.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
    text.content = msg
  end

  node << (extra = Blather::XMPPNode.new('extra-error', node.document))
  extra.namespace = 'blather:stream:error'
  extra.content = 'Blather Error'

  node
end

describe 'Blather::StreamError' do
  it 'can import a node' do
    err = stream_error_node 'internal-server-error', 'the message'
    Blather::StreamError.should respond_to :import
    e = Blather::StreamError.import err
    e.should be_kind_of Blather::StreamError

    e.name.should == :internal_server_error
    e.text.should == 'the message'
    e.extras.should == err.find('descendant::*[name()="extra-error"]', 'blather:stream:error').map {|n|n}
  end
end

describe 'Blather::StreamError when instantiated' do
  before do
    @err_name = 'internal-server-error'
    @msg = 'the server has experienced a misconfiguration'
    @err = Blather::StreamError.import stream_error_node(@err_name, @msg)
  end

  it 'provides a err_name attribute' do
    @err.should respond_to :name
    @err.name.should == @err_name.gsub('-','_').to_sym
  end

  it 'provides a text attribute' do
    @err.should respond_to :text
    @err.text.should == @msg
  end

  it 'provides an extras attribute' do
    @err.should respond_to :extras
    @err.extras.should be_instance_of Array
    @err.extras.size.should == 1
    @err.extras.first.element_name.should == 'extra-error'
  end

  it 'describes itself' do
    @err.to_s.should match(/#{@type}/)
    @err.to_s.should match(/#{@msg}/)

    @err.inspect.should match(/#{@type}/)
    @err.inspect.should match(/#{@msg}/)
  end

  it 'can be turned into xml' do
    @err.should respond_to :to_xml
    doc = parse_stanza @err.to_xml
    doc.xpath("//err_ns:internal-server-error", :err_ns => Blather::StreamError::STREAM_ERR_NS).should_not be_empty
    doc.xpath("//err_ns:text[.='the server has experienced a misconfiguration']", :err_ns => Blather::StreamError::STREAM_ERR_NS).should_not be_empty
    doc.xpath("//err_ns:extra-error[.='Blather Error']", :err_ns => 'blather:stream:error').should_not be_empty
  end


  describe '#to_xml' do
    it 'accepts optional formatting options' do
      # without spaces
      string = @err.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
      expect(string).to eq "<stream:error xmlns:stream=\"http://etherx.jabber.org/streams\"><internal-server-error xmlns=\"urn:ietf:params:xml:ns:xmpp-streams\"/><text xmlns=\"urn:ietf:params:xml:ns:xmpp-streams\">the server has experienced a misconfiguration</text><extra-error xmlns=\"blather:stream:error\">Blather Error</extra-error></stream:error>"
    end
  end
end

describe 'Each XMPP stream error type' do
  %w[ bad-format
      bad-namespace-prefix
      conflict
      connection-timeout
      host-gone
      host-unknown
      improper-addressing
      internal-server-error
      invalid-from
      invalid-id
      invalid-namespace
      invalid-xml
      not-authorized
      policy-violation
      remote-connection-failed
      resource-constraint
      restricted-xml
      see-other-host
      system-shutdown
      undefined-condition
      unsupported-encoding
      unsupported-stanza-type
      unsupported-version
      xml-not-well-formed
    ].each do |error_type|
      it "handles the name for #{error_type}" do
        e = Blather::StreamError.import stream_error_node(error_type)
        e.name.should == error_type.gsub('-','_').to_sym
      end
    end
end
