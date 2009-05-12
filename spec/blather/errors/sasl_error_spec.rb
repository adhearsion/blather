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

  describe 'each XMPP SASL error type' do
    %w[ aborted
        incorrect-encoding
        invalid-authzid
        invalid-mechanism
        mechanism-too-weak
        not-authorized
        temporary-auth-failure
    ].each do |error_type|
      it "handles the name for #{error_type}" do
        e = SASLError.import sasl_error_node(error_type)
        e.name.must_equal error_type.gsub('-','_').to_sym
      end
    end
  end
end
