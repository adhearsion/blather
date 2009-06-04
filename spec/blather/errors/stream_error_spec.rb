require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

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
    Blather::StreamError.must_respond_to :import
    e = Blather::StreamError.import err
    e.must_be_kind_of Blather::StreamError

    e.name.must_equal :internal_server_error
    e.text.must_equal 'the message'
    e.extras.must_equal err.find('descendant::*[name()="extra-error"]', 'blather:stream:error').map {|n|n}
  end
end

describe 'Blather::StreamError when instantiated' do
  before do
    @err_name = 'internal-server-error'
    @msg = 'the server has experienced a misconfiguration'
    @err = Blather::StreamError.import stream_error_node(@err_name, @msg)
  end

  it 'provides a err_name attribute' do
    @err.must_respond_to :name
    @err.name.must_equal @err_name.gsub('-','_').to_sym
  end

  it 'provides a text attribute' do
    @err.must_respond_to :text
    @err.text.must_equal @msg
  end

  it 'provides an extras attribute' do
    @err.must_respond_to :extras
    @err.extras.must_be_instance_of Array
    @err.extras.size.must_equal 1
    @err.extras.first.element_name.must_equal 'extra-error'
  end

  it 'describes itself' do
    @err.to_s.must_match(/#{@type}/)
    @err.to_s.must_match(/#{@msg}/)

    @err.inspect.must_match(/#{@type}/)
    @err.inspect.must_match(/#{@msg}/)
  end

  it 'can be turned into xml' do
    @err.must_respond_to :to_xml
    doc = parse_stanza @err.to_xml
    doc.xpath("//err_ns:internal-server-error", :err_ns => Blather::StreamError::STREAM_ERR_NS).wont_be_empty
    doc.xpath("//err_ns:text[.='the server has experienced a misconfiguration']", :err_ns => Blather::StreamError::STREAM_ERR_NS).wont_be_empty
    doc.xpath("//err_ns:extra-error[.='Blather Error']", :err_ns => 'blather:stream:error').wont_be_empty
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
        e.name.must_equal error_type.gsub('-','_').to_sym
      end
    end
end
