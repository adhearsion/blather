require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

def sasl_error_node(err_name = 'aborted')
  node = XMPPNode.new 'failure'
  node.namespace = 'urn:ietf:params:xml:ns:xmpp-sasl'

  node << XMPPNode.new(err_name)
  node
end

describe 'Blather::SASLError' do
  it 'can import a node' do
    SASLError.must_respond_to :import
    e = SASLError.import sasl_error_node
    e.must_be_kind_of SASLError
  end

  it 'knows what class to instantiate' do
    e = SASLError.import sasl_error_node
    e.must_be_instance_of SASLError::Aborted
  end

  describe 'when instantiated' do
    before do
      @err_name = 'mechanism-too-weak'
      @err = SASLError.import sasl_error_node(@err_name)
    end

    it 'provides a err_name attribute' do
      @err.must_respond_to :err_name
      @err.err_name.must_equal @err_name
    end
  end

  describe 'each XMPP SASL error type' do
    %w[ aborted
        incorrect-encoding
        invalid-authzid
        invalid-mechanism
        mechanism-too-weak
        not-authorized
        temporary-auth-failure
    ].each do |error_type|
      it "provides a class for #{error_type}" do
        e = SASLError.import sasl_error_node(error_type)
        klass = error_type.gsub(/^\w/) { |v| v.upcase }.gsub(/\-(\w)/) { |v| v.delete('-').upcase }
        e.must_be_instance_of eval("SASLError::#{klass}")
      end

      it "registers #{error_type} in the handler heirarchy" do
        e = SASLError.import sasl_error_node(error_type)
        e.handler_heirarchy.must_equal ["sasl_#{error_type.gsub('-','_').gsub('_error','')}_error".to_sym, :sasl_error, :error]
      end
    end
  end
end
