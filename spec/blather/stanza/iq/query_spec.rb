require 'spec_helper'

describe Blather::Stanza::Iq::Query do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:query, nil)).to eq(Blather::Stanza::Iq::Query)
  end

  it 'can be imported' do
    string = <<-XML
      <iq from='juliet@example.com/balcony' type='set' id='roster_4'>
        <query>
          <item jid='nurse@example.com' subscription='remove'/>
        </query>
      </iq>
    XML
    expect(Blather::XMPPNode.parse(string)).to be_instance_of Blather::Stanza::Iq::Query
  end

  it 'ensures a query node is present on create' do
    query = Blather::Stanza::Iq::Query.new
    expect(query.xpath('query')).not_to be_empty
  end

  it 'ensures a query node exists when calling #query' do
    query = Blather::Stanza::Iq::Query.new
    query.remove_child :query
    expect(query.xpath('query')).to be_empty

    expect(query.query).not_to be_nil
    expect(query.xpath('query')).not_to be_empty
  end

  [:get, :set, :result, :error].each do |type|
    it "can be set as \"#{type}\"" do
      query = Blather::Stanza::Iq::Query.new type
      expect(query.type).to eq(type)
    end
  end

  it 'sets type to "result" on reply' do
    query = Blather::Stanza::Iq::Query.new
    expect(query.type).to eq(:get)
    reply = expect(query.reply.type).to eq(:result)
  end

  it 'sets type to "result" on reply!' do
    query = Blather::Stanza::Iq::Query.new
    expect(query.type).to eq(:get)
    query.reply!
    expect(query.type).to eq(:result)
  end

  it 'can be registered under a namespace' do
    class QueryNs < Blather::Stanza::Iq::Query; register :query_ns, nil, 'query:ns'; end
    expect(Blather::XMPPNode.class_from_registration(:query, 'query:ns')).to eq(QueryNs)
    query_ns = QueryNs.new
    expect(query_ns.xpath('query')).to be_empty
    expect(query_ns.xpath('ns:query', :ns => 'query:ns').size).to eq(1)

    query_ns.query
    query_ns.query
    expect(query_ns.xpath('ns:query', :ns => 'query:ns').size).to eq(1)
  end
end
