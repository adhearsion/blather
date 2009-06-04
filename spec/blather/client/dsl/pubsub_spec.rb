require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require 'blather/client/dsl'

describe Blather::DSL::PubSub do
  before do
    @host = 'host.name'
    @pubsub = Blather::DSL::PubSub.new @host
    @client = mock()
    @client.stubs(:jid).returns Blather::JID.new('n@d/r')
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
      n.must_be_instance_of Blather::Stanza::PubSub::Items
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.items '/path/to/node'
  end

  it 'requests specific items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Items
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node'][ns:item[@id='item1']][ns:item[@id='item2']]", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.items '/path/to/node', %w[item1 item2]
  end

  it 'requests some items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Items
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node' and @max_items='2']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :get
    end
    @pubsub.items '/path/to/node', nil, 2
  end

  it 'can publish items to a node with a hash' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Publish
      n.find("/iq[@type='set']/ns:pubsub/ns:publish[@node='/path/to/node' and ns:item[@id='id1' and .='payload1'] and ns:item[@id='id2' and .='payload2']]", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.publish '/path/to/node', {'id1' => 'payload1', 'id2' => 'payload2'}
  end

  it 'can publish items to a node with an array' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Publish
      n.find("/iq[@type='set']/ns:pubsub/ns:publish[@node='/path/to/node' and ns:item[.='payload1'] and ns:item[.='payload2']]", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.publish '/path/to/node', %w[payload1 payload2]
  end

  it 'can publish items to a node with a string' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Publish
      n.find("/iq[@type='set']/ns:pubsub/ns:publish[@node='/path/to/node' and ns:item[.='payload']]", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.publish '/path/to/node', 'payload'
  end

  it 'can retract an item with an array' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Retract
      n.find("/iq[@type='set']/ns:pubsub/ns:retract[@node='/path/to/node' and ns:item[@id='id1'] and ns:item[@id='id2']]", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.retract '/path/to/node', %w[id1 id2]
  end

  it 'can retract an item with a string' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Retract
      n.find("/iq[@type='set']/ns:pubsub/ns:retract[@node='/path/to/node' and ns:item[@id='id1']]", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.retract '/path/to/node', 'id1'
  end

  it 'can subscribe to a node with the default jid' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Subscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:subscribe[@node='/path/to/node' and @jid='#{@client.jid.stripped}']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.subscribe '/path/to/node'
  end

  it 'can subscribe to a node with a specified jid as a string' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Subscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:subscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.subscribe '/path/to/node', 'jid@d/r'
  end

  it 'can subscribe to a node with a specified jid as a Blather::JID' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Subscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:subscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.subscribe '/path/to/node', Blather::JID.new('jid@d/r')
  end

  it 'can unsubscribe to a node with the default jid' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Unsubscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:unsubscribe[@node='/path/to/node' and @jid='#{@client.jid.stripped}']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.unsubscribe '/path/to/node'
  end

  it 'can unsubscribe to a node with a specified jid as a string' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Unsubscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:unsubscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.unsubscribe '/path/to/node', 'jid@d/r'
  end

  it 'can unsubscribe to a node with a specified jid as a Blather::JID' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Unsubscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:unsubscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.unsubscribe '/path/to/node', Blather::JID.new('jid@d/r')
  end

  it 'can purge a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSubOwner::Purge
      n.find("/iq[@type='set']/ns:pubsub/ns:purge[@node='/path/to/node']", :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.purge '/path/to/node'
  end

  it 'can create a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSub::Create
      n.find("/iq[@type='set']/ns:pubsub/ns:create[@node='/path/to/node']", :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.create '/path/to/node'
  end

  it 'can delete a node' do
    @client.expects(:write_with_handler).with do |n|
      n.must_be_instance_of Blather::Stanza::PubSubOwner::Delete
      n.find("/iq[@type='set']/ns:pubsub/ns:delete[@node='/path/to/node']", :ns => Blather::Stanza::PubSubOwner.registered_ns).wont_be_empty
      n.to.must_equal Blather::JID.new(@host)
      n.type.must_equal :set
    end
    @pubsub.delete '/path/to/node'
  end
end
