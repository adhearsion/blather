require 'spec_helper'

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
    expect(Blather::StanzaError).to respond_to :import
    e = Blather::StanzaError.import stanza_error_node
    expect(e).to be_kind_of Blather::StanzaError
  end

  describe 'valid types' do
    before { @original = Blather::Stanza::Message.new 'error@jabber.local', 'test message', :error }

    it 'ensures type is one of Stanza::Message::VALID_TYPES' do
      expect { Blather::StanzaError.new @original, :gone, :invalid_type_name }.to raise_error(Blather::ArgumentError)

      Blather::StanzaError::VALID_TYPES.each do |valid_type|
        msg = Blather::StanzaError.new @original, :gone, valid_type
        expect(msg.type).to eq(valid_type)
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
      expect(@err).to respond_to :type
      expect(@err.type).to eq(@type.to_sym)
    end

    it 'provides a name attribute' do
      expect(@err).to respond_to :name
      expect(@err.name).to eq(@err_name.gsub('-','_').to_sym)
    end

    it 'provides a text attribute' do
      expect(@err).to respond_to :text
      expect(@err.text).to eq(@msg)
    end

    it 'provides a reader to the original node' do
      expect(@err).to respond_to :original
      expect(@err.original).to be_instance_of Blather::Stanza::Message
    end

    it 'provides an extras attribute' do
      expect(@err).to respond_to :extras
      expect(@err.extras).to be_instance_of Array
      expect(@err.extras.first.element_name).to eq('extra-error')
    end

    it 'describes itself' do
      expect(@err.to_s).to match(/#{@err_name}/)
      expect(@err.to_s).to match(/#{@msg}/)

      expect(@err.inspect).to match(/#{@err_name}/)
      expect(@err.inspect).to match(/#{@msg}/)
    end

    it 'can be turned into xml' do
      expect(@err).to respond_to :to_xml
      doc = parse_stanza @err.to_xml

      expect(doc.xpath("/message[@from='error@jabber.local' and @type='error']")).not_to be_empty
      expect(doc.xpath("/message/error")).not_to be_empty
      expect(doc.xpath("/message/error/err_ns:internal-server-error", :err_ns => Blather::StanzaError::STANZA_ERR_NS)).not_to be_empty
      expect(doc.xpath("/message/error/err_ns:text[.='the server has experienced a misconfiguration']", :err_ns => Blather::StanzaError::STANZA_ERR_NS)).not_to be_empty
      expect(doc.xpath("/message/error/extra_ns:extra-error[.='Blather Error']", :extra_ns => 'blather:stanza:error')).not_to be_empty
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
          expect(e.name).to eq(error_type.gsub('-','_').to_sym)
        end
      end
  end
end
