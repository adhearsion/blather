require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

def stream_error_node(error = 'internal-server-error', msg = nil)
  node = XMPPNode.new('stream:error')
  XML::Document.new.root = node
  
  err = XMPPNode.new(error)
  err.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
  node << err

  if msg
    text = XMPPNode.new('text')
    text.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
    text << msg
    node << text
  end

  extra = XMPPNode.new('extra-error')
  extra.namespace = 'blather:stream:error'
  extra << 'Blather Error'

  node << extra
  node
end

describe 'Blather::StreamError' do
  it 'can import a node' do
    StreamError.must_respond_to :import
    e = StreamError.import stream_error_node
    e.must_be_kind_of StreamError
  end

  it 'knows what class to instantiate' do
    e = StreamError.import stream_error_node
    e.must_be_instance_of StreamError::InternalServerError
  end

  describe 'when instantiated' do
    before do
      @err_name = 'internal-server-error'
      @msg = 'the server has experienced a misconfiguration'
      @err = StreamError.import stream_error_node(@err_name, @msg)
    end

    it 'provides a err_name attribute' do
      @err.must_respond_to :err_name
      @err.err_name.must_equal @err_name
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
      @err.to_xml.must_equal "<stream:error>\n<internal-server-error xmlns=\"urn:ietf:params:xml:ns:xmpp-streams\"/>\n<text xmlns=\"urn:ietf:params:xml:ns:xmpp-streams\">the server has experienced a misconfiguration</text>\n<extra-error xmlns=\"blather:stream:error\">Blather Error</extra-error>\n</stream:error>"
    end
  end

  describe 'each XMPP stream error type' do
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
        it "provides a class for #{error_type}" do
          e = StreamError.import stream_error_node(error_type)
          klass = error_type.gsub(/^\w/) { |v| v.upcase }.gsub(/\-(\w)/) { |v| v.delete('-').upcase }
          e.must_be_instance_of eval("StreamError::#{klass}")
        end

        it "registers #{error_type} in the handler heirarchy" do
          e = StreamError.import stream_error_node(error_type)
          e.handler_heirarchy.must_equal ["stream_#{error_type.gsub('-','_').gsub('_error','')}_error".to_sym, :stream_error, :error]
        end
      end
  end
end


