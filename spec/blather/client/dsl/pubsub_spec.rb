require 'spec_helper'
require 'fixtures/pubsub'
require 'blather/client/dsl'

describe Blather::DSL::PubSub do
  before do
    @host = 'host.name'
    @client = mock()
    @client.stubs(:jid).returns Blather::JID.new('n@d/r')
    @pubsub = Blather::DSL::PubSub.new @client, @host
  end

  it 'raises an error when trying to send a stanza without a host' do
    @pubsub.host = nil
    proc { @pubsub.affiliations }.should raise_error RuntimeError
  end

  it 'requests affiliations' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Affiliations
      n.find('//ns:pubsub/ns:affiliations', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.affiliations
  end

  it 'requests affiliations from a specified host' do
    host = 'another.host'
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Affiliations
      n.find('//ns:pubsub/ns:affiliations', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(host)
      n.type.should == :get
    end
    @pubsub.affiliations host
  end

  it 'requests subscriptions' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Subscriptions
      n.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.subscriptions
  end

  it 'requests subscriptions from a specified host' do
    host = 'another.host'
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Subscriptions
      n.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(host)
      n.type.should == :get
    end
    @pubsub.subscriptions host
  end

  it 'requests nodes defaulting to "/"' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::DiscoItems
      n.find("/iq/ns:query[@node='/']", :ns => Blather::Stanza::DiscoItems.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.nodes nil
  end

  it 'requests nodes from a specified host' do
    host = 'another.host'
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::DiscoItems
      n.find("/iq/ns:query[@node='/']", :ns => Blather::Stanza::DiscoItems.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(host)
      n.type.should == :get
    end
    @pubsub.nodes nil, host
  end

  it 'requests nodes under a specified path' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::DiscoItems
      n.find("/iq/ns:query[@node='/path/to/nodes']", :ns => Blather::Stanza::DiscoItems.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.nodes '/path/to/nodes'
  end

  it 'requests information on a node' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::DiscoInfo
      n.find("/iq/ns:query[@node='/path/to/node']", :ns => Blather::Stanza::DiscoInfo.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.node '/path/to/node'
  end

  it 'requests all items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Items
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.items '/path/to/node'
  end

  it 'requests specific items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Items
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node'][ns:item[@id='item1']][ns:item[@id='item2']]", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.items '/path/to/node', %w[item1 item2]
  end

  it 'requests some items from a node' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Items
      n.find("/iq/ns:pubsub/ns:items[@node='/path/to/node' and @max_items='2']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :get
    end
    @pubsub.items '/path/to/node', nil, 2
  end

  it 'can publish items to a node with a hash' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Publish
      n.find("/iq[@type='set']/ns:pubsub/ns:publish[@node='/path/to/node' and ns:item[@id='id1' and .='payload1'] and ns:item[@id='id2' and .='payload2']]", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.publish '/path/to/node', {'id1' => 'payload1', 'id2' => 'payload2'}
  end

  it 'can publish items to a node with an array' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Publish
      n.find("/iq[@type='set']/ns:pubsub/ns:publish[@node='/path/to/node' and ns:item[.='payload1'] and ns:item[.='payload2']]", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.publish '/path/to/node', %w[payload1 payload2]
  end

  it 'can publish items to a node with a string' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Publish
      n.find("/iq[@type='set']/ns:pubsub/ns:publish[@node='/path/to/node' and ns:item[.='payload']]", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.publish '/path/to/node', 'payload'
  end

  it 'can retract an item with an array' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Retract
      n.find("/iq[@type='set']/ns:pubsub/ns:retract[@node='/path/to/node' and ns:item[@id='id1'] and ns:item[@id='id2']]", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.retract '/path/to/node', %w[id1 id2]
  end

  it 'can retract an item with a string' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Retract
      n.find("/iq[@type='set']/ns:pubsub/ns:retract[@node='/path/to/node' and ns:item[@id='id1']]", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.retract '/path/to/node', 'id1'
  end

  it 'can subscribe to a node with the default jid' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Subscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:subscribe[@node='/path/to/node' and @jid='#{@client.jid.stripped}']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.subscribe '/path/to/node'
  end

  it 'can subscribe to a node with a specified jid as a string' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Subscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:subscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.subscribe '/path/to/node', 'jid@d/r'
  end

  it 'can subscribe to a node with a specified jid as a Blather::JID' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Subscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:subscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.subscribe '/path/to/node', Blather::JID.new('jid@d/r')
  end

  it 'can unsubscribe to a node with the default jid' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Unsubscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:unsubscribe[@node='/path/to/node' and @jid='#{@client.jid.stripped}']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.unsubscribe '/path/to/node'
  end

  it 'can unsubscribe to a node with a specified jid as a string' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Unsubscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:unsubscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.unsubscribe '/path/to/node', 'jid@d/r'
  end

  it 'can unsubscribe to a node with a specified jid as a Blather::JID' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Unsubscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:unsubscribe[@node='/path/to/node' and @jid='jid@d/r']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.unsubscribe '/path/to/node', Blather::JID.new('jid@d/r')
  end

  it 'can unsubscribe with a particular subscription id' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Unsubscribe
      n.find("/iq[@type='set']/ns:pubsub/ns:unsubscribe[@node='/path/to/node' and @jid='jid@d/r' and @subid='subid']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.subid.should == 'subid'
      n.type.should == :set
    end
    @pubsub.unsubscribe '/path/to/node', 'jid@d/r', 'subid'
  end

  it 'can purge a node' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSubOwner::Purge
      n.find("/iq[@type='set']/ns:pubsub/ns:purge[@node='/path/to/node']", :ns => Blather::Stanza::PubSubOwner.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.purge '/path/to/node'
  end

  it 'can create a node' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Create
      n.find("/iq[@type='set']/ns:pubsub/ns:create[@node='/path/to/node']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.create '/path/to/node'
  end

  it 'can create a node with configuration' do
    pubsub_configure = Blather::Stanza::X.new({
      :type => :submit,
      :fields => [
        { :var => "FORM_TYPE", :type => 'hidden', :value => "http://jabber.org/protocol/pubsub#node_config" },
        { :var => "pubsub#persist_items", :value => "0" },
        { :var => "pubsub#max_items", :value => "0" },
        { :var => "pubsub#notify_retract",  :value => "0" },
        { :var => "pubsub#publish_model", :value => "open" }]
    })
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSub::Create
      n.find("/iq[@type='set']/ns:pubsub/ns:create[@node='/path/to/node']", :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
      n.configure_node.should == pubsub_configure
    end
    @pubsub.create '/path/to/node', nil, pubsub_configure
  end

  it 'can delete a node' do
    @client.expects(:write_with_handler).with do |n|
      n.should be_instance_of Blather::Stanza::PubSubOwner::Delete
      n.find("/iq[@type='set']/ns:pubsub/ns:delete[@node='/path/to/node']", :ns => Blather::Stanza::PubSubOwner.registered_ns).should_not be_empty
      n.to.should == Blather::JID.new(@host)
      n.type.should == :set
    end
    @pubsub.delete '/path/to/node'
  end
end

describe 'Blather::DSL::PubSub callbacks' do
  before do
    @host = 'host.name'
    @client = Blather::Client.setup Blather::JID.new('n@d/r'), 'pass'
    @pubsub = Blather::DSL::PubSub.new @client, @host
  end

  it 'returns a list of affiliations when requesting affiliations' do
    affiliations = Blather::XMPPNode.parse(affiliations_xml)
    response = mock()
    response.expects(:call).with { |n| n.should == affiliations.list }
    @client.stubs(:write).with do |n|
      affiliations.id = n.id
      @client.receive_data affiliations
      true
    end
    @pubsub.affiliations { |n| response.call n }
  end

  it 'returns a list of subscriptions when requesting subscriptions' do
    subscriptions = Blather::XMPPNode.parse(subscriptions_xml)
    response = mock()
    response.expects(:call).with { |n| n.should == subscriptions.list }
    @client.stubs(:write).with do |n|
      subscriptions.id = n.id
      @client.receive_data subscriptions
      true
    end
    @pubsub.subscriptions { |n| response.call n }
  end

  it 'returns a list of node items when requesting nodes' do
    nodes = Blather::XMPPNode.parse(<<-NODES)
    <iq type='result'
        from='pubsub.shakespeare.lit'
        to='francisco@denmark.lit/barracks'
        id='nodes1'>
      <query xmlns='http://jabber.org/protocol/disco#items'>
        <item jid='pubsub.shakespeare.lit'
              node='blogs'
              name='Weblog updates'/>
        <item jid='pubsub.shakespeare.lit'
              node='news'
              name='News and announcements'/>
      </query>
    </iq>
    NODES
    response = mock()
    response.expects(:call).with { |n| n.should == nodes.items }
    @client.stubs(:write).with do |n|
      nodes.id = n.id
      @client.receive_data nodes
      true
    end
    @pubsub.nodes { |n| response.call n }
  end

  it 'returns a DiscoInfo node when requesting a node' do
    node = Blather::XMPPNode.parse(<<-NODES)
    <iq type='result'
        from='pubsub.shakespeare.lit'
        to='francisco@denmark.lit/barracks'
        id='meta1'>
      <query xmlns='http://jabber.org/protocol/disco#info'
             node='blogs'>
        <identity category='pubsub' type='collection'/>
      </query>
    </iq>
    NODES
    response = mock()
    response.expects(:call).with { |n| n.should == node }
    @client.stubs(:write).with do |n|
      node.id = n.id
      @client.receive_data node
      true
    end
    @pubsub.node('blogs') { |n| response.call n }
  end

  it 'returns a set of items when requesting items' do
    items = Blather::XMPPNode.parse(items_all_nodes_xml)
    response = mock()
    response.expects(:call).with { |n| n.map{|i|i.to_s}.should == items.items.map{|i|i.to_s} }
    @client.stubs(:write).with do |n|
      items.id = n.id
      @client.receive_data items
      true
    end
    @pubsub.items('princely_musings') { |n| response.call n }
  end

  it 'returns aa subscription node when subscribing' do
    subscription = Blather::XMPPNode.parse(subscription_xml)
    response = mock()
    response.expects(:call).with { |n| n.should == subscription }
    @client.stubs(:write).with do |n|
      subscription.id = n.id
      @client.receive_data subscription
      true
    end
    @pubsub.subscribe('princely_musings') { |n| response.call n }
  end

  it 'returns aa unsubscribe node when unsubscribing' do
    unsubscribe = Blather::XMPPNode.parse(unsubscribe_xml)
    response = mock()
    response.expects(:call).with { |n| n.should == unsubscribe }
    @client.stubs(:write).with do |n|
      unsubscribe.id = n.id
      @client.receive_data unsubscribe
      true
    end
    @pubsub.unsubscribe('princely_musings') { |n| response.call n }
  end

  it 'returns a publish result when publishing to a node' do
    result = Blather::XMPPNode.parse(<<-NODE)
    <iq type='result'
        from='pubsub.shakespeare.lit'
        to='hamlet@denmark.lit/blogbot'
        id='publish1'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <publish node='princely_musings'>
          <item id='ae890ac52d0df67ed7cfdf51b644e901'/>
        </publish>
      </pubsub>
    </iq>
    NODE
    response = mock()
    response.expects(:call).with { |n| n.should == result }
    @client.stubs(:write).with do |n|
      result.id = n.id
      @client.receive_data result
      true
    end
    @pubsub.publish('princely_musings', 'payload') { |n| response.call n }
  end

  it 'returns a create result when creating a node' do
    result = Blather::XMPPNode.parse(<<-NODE)
    <iq type='result'
        from='pubsub.shakespeare.lit'
        to='hamlet@denmark.lit/elsinore'
        id='create2'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
          <create node='25e3d37dabbab9541f7523321421edc5bfeb2dae'/>
        </pubsub>
    </iq>
    NODE
    response = mock()
    response.expects(:call).with { |n| n.should == result }
    @client.stubs(:write).with do |n|
      result.id = n.id
      @client.receive_data result
      true
    end
    @pubsub.create('princely_musings') { |n| response.call n }
  end

  it 'returns a purge result when purging a node' do
    result = Blather::XMPPNode.parse(<<-NODE)
    <iq type='result'
        from='pubsub.shakespeare.lit'
        id='purge1'/>
    NODE
    response = mock()
    response.expects(:call).with { |n| n.should == result }
    @client.stubs(:write).with do |n|
      result.id = n.id
      @client.receive_data result
      true
    end
    @pubsub.purge('princely_musings') { |n| response.call n }
  end

  it 'returns a delete result when deleting a node' do
    result = Blather::XMPPNode.parse(<<-NODE)
    <iq type='result'
        from='pubsub.shakespeare.lit'
        id='delete1'/>
    NODE
    response = mock()
    response.expects(:call).with { |n| n.should == result }
    @client.stubs(:write).with do |n|
      result.id = n.id
      @client.receive_data result
      true
    end
    @pubsub.delete('princely_musings') { |n| response.call n }
  end
end
