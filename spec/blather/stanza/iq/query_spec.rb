require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

describe 'Blather::Stanza::Iq::Query' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:query, nil).must_equal Stanza::Iq::Query
  end

  it 'ensures a query node is present on create' do
    query = Stanza::Iq::Query.new
    query.children.detect { |n| n.element_name == 'query' }.wont_be_nil
  end

  it 'ensures a query node exists when calling #query' do
    query = Stanza::Iq::Query.new
    query.remove_child :query
    query.children.detect { |n| n.element_name == 'query' }.must_be_nil

    query.query.wont_be_nil
    query.children.detect { |n| n.element_name == 'query' }.wont_be_nil
  end

  it 'sets type to "result" on reply' do
    query = Stanza::Iq::Query.new
    query.type.must_equal :get
    reply = query.reply.type.must_equal :result
  end

  it 'sets type to "result" on reply!' do
    query = Stanza::Iq::Query.new
    query.type.must_equal :get
    query.reply!
    query.type.must_equal :result
  end
end