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
    expect(Blather::StreamError).to respond_to :import
    e = Blather::StreamError.import err
    expect(e).to be_kind_of Blather::StreamError

    expect(e.name).to eq(:internal_server_error)
    expect(e.text).to eq('the message')
    expect(e.extras).to eq(err.find('descendant::*[name()="extra-error"]', 'blather:stream:error').map {|n|n})
  end
end

describe 'Blather::StreamError when instantiated' do
  before do
    @err_name = 'internal-server-error'
    @msg = 'the server has experienced a misconfiguration'
    @err = Blather::StreamError.import stream_error_node(@err_name, @msg)
  end

  it 'provides a err_name attribute' do
    expect(@err).to respond_to :name
    expect(@err.name).to eq(@err_name.gsub('-','_').to_sym)
  end

  it 'provides a text attribute' do
    expect(@err).to respond_to :text
    expect(@err.text).to eq(@msg)
  end

  it 'provides an extras attribute' do
    expect(@err).to respond_to :extras
    expect(@err.extras).to be_instance_of Array
    expect(@err.extras.size).to eq(1)
    expect(@err.extras.first.element_name).to eq('extra-error')
  end

  it 'describes itself' do
    expect(@err.to_s).to match(/#{@type}/)
    expect(@err.to_s).to match(/#{@msg}/)

    expect(@err.inspect).to match(/#{@type}/)
    expect(@err.inspect).to match(/#{@msg}/)
  end

  it 'can be turned into xml' do
    expect(@err).to respond_to :to_xml
    doc = parse_stanza @err.to_xml
    expect(doc.xpath("//err_ns:internal-server-error", :err_ns => Blather::StreamError::STREAM_ERR_NS)).not_to be_empty
    expect(doc.xpath("//err_ns:text[.='the server has experienced a misconfiguration']", :err_ns => Blather::StreamError::STREAM_ERR_NS)).not_to be_empty
    expect(doc.xpath("//err_ns:extra-error[.='Blather Error']", :err_ns => 'blather:stream:error')).not_to be_empty
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
        expect(e.name).to eq(error_type.gsub('-','_').to_sym)
      end
    end
end
