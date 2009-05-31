require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

def sasl_error_node(err_name = 'aborted')
  node = Blather::XMPPNode.new 'failure'
  node.namespace = Blather::SASLError::SASL_ERR_NS

  node << Blather::XMPPNode.new(err_name, node.document)
  node
end

describe Blather::SASLError do
  it 'can import a node' do
    Blather::SASLError.must_respond_to :import
    e = Blather::SASLError.import sasl_error_node
    e.must_be_kind_of Blather::SASLError
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
        e = Blather::SASLError.import sasl_error_node(error_type)
        e.name.must_equal error_type.gsub('-','_').to_sym
      end
    end
  end
end
