require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

def stanza_error_node(type = 'cancel', error = 'internal-server-error', msg = nil)
  node = Stanza::Message.new 'error@jabber.local', 'test message', :error
  XML::Document.new.root = node

  error_node = XMPPNode.new('error')
  error_node['type'] = type.to_s
  
  err = XMPPNode.new(error)
  err.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
  error_node << err

  if msg
    text = XMPPNode.new('text')
    text.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
    text << msg
    error_node << text
  end

  extra = XMPPNode.new('extra-error')
  extra.namespace = 'blather:stanza:error'
  extra << 'Blather Error'
  error_node << extra

  node << error_node
  node
end

describe 'Blather::StanzaError' do
  it 'can import a node' do
    StanzaError.must_respond_to :import
    e = StanzaError.import stanza_error_node
    e.must_be_kind_of StanzaError
  end

  it 'knows what class to instantiate' do
    e = StanzaError.import stanza_error_node
    e.must_be_instance_of StanzaError::InternalServerError
  end

  describe 'valid types' do
    before { @original = Stanza::Message.new 'error@jabber.local', 'test message', :error }

    it 'ensures type is one of Stanza::Message::VALID_TYPES' do
      lambda { StanzaError.new @original, :invalid_type_name }.must_raise(Blather::ArgumentError)

      StanzaError::VALID_TYPES.each do |valid_type|
        msg = StanzaError.new @original, valid_type
        msg.type.must_equal valid_type
      end
    end
  end

  describe 'when instantiated' do
    before do
      @type = 'cancel'
      @err_name = 'internal-server-error'
      @msg = 'the server has experienced a misconfiguration'
      @err = StanzaError.import stanza_error_node(@type, @err_name, @msg)
    end

    it 'provides a type attribute' do
      @err.must_respond_to :type
      @err.type.must_equal @type.to_sym
    end

    it 'provides a err_name attribute' do
      @err.must_respond_to :err_name
      @err.err_name.must_equal @err_name
    end

    it 'provides a text attribute' do
      @err.must_respond_to :text
      @err.text.must_equal @msg
    end

    it 'provides a reader to the original node' do
      @err.must_respond_to :original
      @err.original.must_be_instance_of Stanza::Message
    end

    it 'provides an extras attribute' do
      @err.must_respond_to :extras
      @err.extras.must_be_instance_of Array
      @err.extras.first.element_name.must_equal 'extra-error'
    end

    it 'describes itself' do
      @err.to_s.must_match(/#{@err_name}/)
      @err.to_s.must_match(/#{@msg}/)

      @err.inspect.must_match(/#{@err_name}/)
      @err.inspect.must_match(/#{@msg}/)
    end

    it 'can be turned into xml' do
      @err.must_respond_to :to_xml
      control = "<body>test message</body>\n<error>\n<internal-server-error xmlns=\"urn:ietf:params:xml:ns:xmpp-stanzas\"/>\n<text xmlns=\"urn:ietf:params:xml:ns:xmpp-stanzas\">the server has experienced a misconfiguration</text>\n<extra-error xmlns=\"blather:stanza:error\">Blather Error</extra-error>\n</error>\n</message>".split("\n")
      test = @err.to_xml.split("\n")
      test_msg = test.shift
      test.must_equal control

      test_msg.must_match(/<message[^>]*id="#{@err.original.id}"/)
      test_msg.must_match(/<message[^>]*from="error@jabber\.local"/)
      test_msg.must_match(/<message[^>]*type="error"/)
    end
  end

  describe 'each XMPP stanza error type' do
    %w[ bad-request
        conflict
        feature-not-implemented
        forbidden
        gone
        internal-server-error
        item-not-found
        jid-malformed
        not-acceptable
        not-allowed
        not-authorized
        payment-required
        recipient-unavailable
        redirect
        registration-required
        remote-server-not-found
        remote-server-timeout
        resource-constraint
        service-unavailable
        subscription-required
        undefined-condition
        unexpected-request
      ].each do |error_type|
        it "provides a class for #{error_type}" do
          e = StanzaError.import stanza_error_node(:cancel, error_type)
          klass = error_type.gsub(/^\w/) { |v| v.upcase }.gsub(/\-(\w)/) { |v| v.delete('-').upcase }
          e.must_be_instance_of eval("StanzaError::#{klass}")
        end

        it "registers #{error_type} in the handler heirarchy" do
          e = StanzaError.import stanza_error_node(:cancel, error_type)
          e.handler_heirarchy.must_equal ["stanza_#{error_type.gsub('-','_').gsub('_error','')}_error".to_sym, :stanza_error, :error]
        end
      end
  end
end


