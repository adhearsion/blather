require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require 'blather/client/dsl'

describe Blather::DSL::PubSub do
  before do
    @host = 'host.name'
    @pubsub = Blather::DSL::PubSub.new @host
    @client = mock()
    Blather::DSL.stubs(:client).returns @client
  end

  it 'raises an error when trying to send a stanza without a host' do
    @pubsub.host = nil
    proc { @pubsub.affiliations }.must_raise RuntimeError
  end

  it 'requests affiliations' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Affiliations
      n.find('//ns:pubsub/ns:affiliations', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.affiliations
  end

  it 'requests affiliations from a specified host' do
    host = 'another.host'
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Affiliations
      n.find('//ns:pubsub/ns:affiliations', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(host)
      n.type.must_equal :get
    end
    @pubsub.affiliations host
  end

  it 'requests subscriptions' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Subscriptions
      n.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.subscriptions
  end

  it 'requests subscriptions from a specified host' do
    host = 'another.host'
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Subscriptions
      n.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(host)
      n.type.must_equal :get
    end
    @pubsub.subscriptions host
  end

  it 'requests nodes defaulting to "/"' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::DiscoItems
      n.find("/iq/ns:query[@node='/']", :ns => Blather::Stanza::DiscoItems.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.nodes nil
  end

  it 'requests nodes from a specified host' do
    host = 'another.host'
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::DiscoItems
      n.find("/iq/ns:query[@node='/']", :ns => Blather::Stanza::DiscoItems.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(host)
      n.type.must_equal :get
    end
    @pubsub.nodes nil, host
  end

  it 'requests nodes under a specified path' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::DiscoItems
      n.find("/iq/ns:query[@node='/path/to/nodes']", :ns => Blather::Stanza::DiscoItems.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.nodes '/path/to/nodes'
  end

  it 'requests information on a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::DiscoInfo
      n.find("/iq/ns:query[@node='/path/to/node']", :ns => Blather::Stanza::DiscoInfo.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.node '/path/to/node'
  end

  it 'requests all items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.items '/path/to/node'
  end

  it 'requests specific items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node'][ns:item[@id='item1']][ns:item[@id='item2']]", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.items '/path/to/node', %w[item1 item2]
  end

  it 'requests some items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node' and @max_items='2']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.items '/path/to/node', nil, 2
  end
end
