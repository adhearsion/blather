require 'spec_helper'

describe Blather::BlatherError do
  it 'is handled by :error' do
    Blather::BlatherError.new.handler_hierarchy.should == [:error]
  end
end

describe 'Blather::ParseError' do
  before { @error = Blather::ParseError.new('</generate-parse-error>"') }

  it 'is registers with the handler hierarchy' do
    @error.handler_hierarchy.should == [:parse_error, :error]
  end

  it 'contains the error message' do
    @error.should respond_to :message
    @error.message.should == '</generate-parse-error>"'
  end
end

describe 'Blather::UnknownResponse' do
  before { @error = Blather::UnknownResponse.new(Blather::XMPPNode.new('foo-bar')) }

  it 'is registers with the handler hierarchy' do
    @error.handler_hierarchy.should == [:unknown_response_error, :error]
  end

  it 'holds on to a copy of the failure node' do
    @error.should respond_to :node
    @error.node.node_name.should == 'foo-bar'
  end
end
