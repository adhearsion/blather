require 'spec_helper'

describe Blather::BlatherError do
  it 'is handled by :error' do
    expect(Blather::BlatherError.new.handler_hierarchy).to eq([:error])
  end
end

describe 'Blather::ParseError' do
  before { @error = Blather::ParseError.new('</generate-parse-error>"') }

  it 'is registers with the handler hierarchy' do
    expect(@error.handler_hierarchy).to eq([:parse_error, :error])
  end

  it 'contains the error message' do
    expect(@error).to respond_to :message
    expect(@error.message).to eq('</generate-parse-error>"')
  end
end

describe 'Blather::UnknownResponse' do
  before { @error = Blather::UnknownResponse.new(Blather::XMPPNode.new('foo-bar')) }

  it 'is registers with the handler hierarchy' do
    expect(@error.handler_hierarchy).to eq([:unknown_response_error, :error])
  end

  it 'holds on to a copy of the failure node' do
    expect(@error).to respond_to :node
    expect(@error.node.element_name).to eq('foo-bar')
  end
end
