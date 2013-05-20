require 'spec_helper'

describe Nokogiri::XML::Node do
  let(:doc) { Nokogiri::XML::Document.new }

  subject { Nokogiri::XML::Node.new 'foo', doc }

  before { doc.root = subject }

  it 'allows symbols as hash keys for attributes' do
    subject['foo'] = 'bar'
    subject['foo'].should == 'bar'
    subject[:foo].should == 'bar'
  end

  it 'removes an attribute when set to nil' do
    subject['foo'] = 'bar'
    subject['foo'].should == 'bar'
    subject['foo'] = nil
    subject['foo'].should be_nil
  end

  it 'allows attribute values to change' do
    subject['foo'] = 'bar'
    subject['foo'].should == 'bar'
    subject['foo'] = 'baz'
    subject['foo'].should == 'baz'
  end
end
