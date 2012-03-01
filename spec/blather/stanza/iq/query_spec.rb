require 'spec_helper'

describe Blather::Stanza::Iq::Query do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:query, nil).must_equal Blather::Stanza::Iq::Query
  end

  it 'can be imported' do
    string = <<-XML
      <iq from='juliet@example.com/balcony' type='set' id='roster_4'>
        <query>
          <item jid='nurse@example.com' subscription='remove'/>
        </query>
      </iq>
    XML
    Blather::XMPPNode.parse(string).must_be_instance_of Blather::Stanza::Iq::Query
  end

  it 'ensures a query node is present on create' do
    query = Blather::Stanza::Iq::Query.new
    query.xpath('query').wont_be_empty
  end

  it 'ensures a query node exists when calling #query' do
    query = Blather::Stanza::Iq::Query.new
    query.remove_child :query
    query.xpath('query').must_be_empty

    query.query.wont_be_nil
    query.xpath('query').wont_be_empty
  end

  [:get, :set, :result, :error].each do |type|
    it "can be set as \"#{type}\"" do
      query = Blather::Stanza::Iq::Query.new type
      query.type.must_equal type
    end
  end

  it 'sets type to "result" on reply' do
    query = Blather::Stanza::Iq::Query.new
    query.type.must_equal :get
    reply = query.reply.type.must_equal :result
  end

  it 'sets type to "result" on reply!' do
    query = Blather::Stanza::Iq::Query.new
    query.type.must_equal :get
    query.reply!
    query.type.must_equal :result
  end

  it 'can be registered under a namespace' do
    class QueryNs < Blather::Stanza::Iq::Query; register :query_ns, nil, 'query:ns'; end
    Blather::XMPPNode.class_from_registration(:query, 'query:ns').must_equal QueryNs
    query_ns = QueryNs.new
    query_ns.xpath('query').must_be_empty
    query_ns.xpath('ns:query', :ns => 'query:ns').size.must_equal 1

    query_ns.query
    query_ns.query
    query_ns.xpath('ns:query', :ns => 'query:ns').size.must_equal 1
  end
end
