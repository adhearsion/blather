require File.expand_path "../../../spec_helper", __FILE__

def stanza_error_node(type = 'cancel', error = 'internal-server-error', msg = nil)
  node = Blather::Stanza::Message.new 'error@jabber.local', 'test message', :error

  node << (error_node = Blather::XMPPNode.new('error'))
  error_node['type'] = type.to_s
  
  error_node << (err = Blather::XMPPNode.new(error, error_node.document))
  err.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'

  if msg
    error_node << (text = Blather::XMPPNode.new('text', error_node.document))
    text.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
    text.content = msg
  end

  error_node << (extra = Blather::XMPPNode.new('extra-error', error_node.document))
  extra.namespace = 'blather:stanza:error'
  extra.content = 'Blather Error'

  node
end

describe Blather::StanzaError do
  it 'can import a node' do
    Blather::StanzaError.must_respond_to :import
    e = Blather::StanzaError.import stanza_error_node
    e.must_be_kind_of Blather::StanzaError
  end

  describe 'valid types' do
    before { @original = Blather::Stanza::Message.new 'error@jabber.local', 'test message', :error }

    it 'ensures type is one of Stanza::Message::VALID_TYPES' do
      lambda { Blather::StanzaError.new @original, :gone, :invalid_type_name }.must_raise(Blather::ArgumentError)

      Blather::StanzaError::VALID_TYPES.each do |valid_type|
        msg = Blather::StanzaError.new @original, :gone, valid_type
        msg.type.must_equal valid_type
      end
    end
  end

  describe 'when instantiated' do
    before do
      @type = 'cancel'
      @err_name = 'internal-server-error'
      @msg = 'the server has experienced a misconfiguration'
      @err = Blather::StanzaError.import stanza_error_node(@type, @err_name, @msg)
    end

    it 'provides a type attribute' do
      @err.must_respond_to :type
      @err.type.must_equal @type.to_sym
    end

    it 'provides a name attribute' do
      @err.must_respond_to :name
      @err.name.must_equal @err_name.gsub('-','_').to_sym
    end

    it 'provides a text attribute' do
      @err.must_respond_to :text
      @err.text.must_equal @msg
    end

    it 'provides a reader to the original node' do
      @err.must_respond_to :original
      @err.original.must_be_instance_of Blather::Stanza::Message
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
      doc = parse_stanza @err.to_xml

      doc.xpath("/message[@from='error@jabber.local' and @type='error']").wont_be_empty
      doc.xpath("/message/error").wont_be_empty
      doc.xpath("/message/error/err_ns:internal-server-error", :err_ns => Blather::StanzaError::STANZA_ERR_NS).wont_be_empty
      doc.xpath("/message/error/err_ns:text[.='the server has experienced a misconfiguration']", :err_ns => Blather::StanzaError::STANZA_ERR_NS).wont_be_empty
      doc.xpath("/message/error/extra_ns:extra-error[.='Blather Error']", :extra_ns => 'blather:stanza:error').wont_be_empty
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
        it "handles the name for #{error_type}" do
          e = Blather::StanzaError.import stanza_error_node(:cancel, error_type)
          e.name.must_equal error_type.gsub('-','_').to_sym
        end
      end
  end
end
