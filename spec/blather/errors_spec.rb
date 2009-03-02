require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe 'Blather::BlatherError' do
  it 'is handled by :error' do
    BlatherError.new.handler_heirarchy.must_equal [:error]
  end
end

describe 'Blather::ParseError' do
  before { @error = ParseError.new('</generate-parse-error>"') }

  it 'is registers with the handler heirarchy' do
    @error.handler_heirarchy.must_equal [:parse_error, :error]
  end

  it 'contains the error message' do
    @error.must_respond_to :message
    @error.message.must_equal '</generate-parse-error>"'
  end
end

describe 'Blather::TLSFailure' do
  it 'is registers with the handler heirarchy' do
    TLSFailure.new.handler_heirarchy.must_equal [:tls_failure, :error]
  end
end

describe 'Blather::UnknownResponse' do
  before { @error = UnknownResponse.new(XMPPNode.new('foo-bar')) }

  it 'is registers with the handler heirarchy' do
    @error.handler_heirarchy.must_equal [:unknown_response_error, :error]
  end

  it 'holds on to a copy of the failure node' do
    @error.must_respond_to :node
    @error.node.element_name.must_equal 'foo-bar'
  end
end

