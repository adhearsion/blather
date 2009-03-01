require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

describe 'Blather::BlatherError' do
  it 'is handled by :error' do
    BlatherError.new.handler_heirarchy.first.must_equal :error
  end
end
