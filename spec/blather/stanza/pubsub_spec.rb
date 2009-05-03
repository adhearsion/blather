require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

describe 'Blather::Stanza::PubSub' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub
  end

  it 'ensures a pubusb node is present on create' do
    pubsub = Stanza::PubSub.new
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.wont_be_nil
  end

  it 'ensures a pubsub node exists when calling #pubsub' do
    pubsub = Stanza::PubSub.new
    pubsub.remove_child :pubsub
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.must_be_nil

    pubsub.pubsub.wont_be_nil
    pubsub.children.detect { |n| n.element_name == 'pubsub' }.wont_be_nil
  end

  it 'can create an subscriptions request node' do
    host = 'pubsub.jabber.local'

    sub = Stanza::PubSub.subscriptions host
    sub.find('//pubsub/subscriptions').size.must_equal 1
    sub.type.must_equal :get
    sub.to.must_equal JID.new(host)
  end

  it 'can create an items request node to request all items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'

    items = Stanza::PubSub.items host, node
    items.find("//pubsub/items[@node=\"#{node}\"]").size.must_equal 1
    items.to.must_equal JID.new(host)
  end

  it 'can create an items request node to request some items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    items = %w[item1 item2]

    items_xpath = items.map { |i| "@id=\"#{i}\"" } * ' or '

    items = Stanza::PubSub.items host, node, items
    items.find("//pubsub/items[@node=\"#{node}\"]/item[#{items_xpath}]").size.must_equal 2
    items.to.must_equal JID.new(host)
  end

  it 'can create an items request node to request "max_number" of items' do
    host = 'pubsub.jabber.local'
    node = 'princely_musings'
    max = 3

    items = Stanza::PubSub.items host, node, nil, max
    items.find("//pubsub/items[@node=\"#{node}\" and @max_items=\"#{max}\"]").size.must_equal 1
    items.to.must_equal JID.new(host)
  end

  it 'can import a subscriptions result node' do
    node = XML::Document.string(<<-NODE).root
      <iq type='result'
          from='pubsub.shakespeare.lit'
          to='francisco@denmark.lit'
          id='affil1'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
          <subscriptions>
            <subscription node='node1' subscription='subscribed'/>
            <subscription node='node2' subscription='subscribed'/>
            <subscription node='node3' subscription='unconfigured'/>
            <subscription node='node4' subscription='pending'/>
            <subscription node='node5' subscription='none'/>
          </subscriptions>
        </pubsub>
      </iq>
    NODE

    pubsub = Stanza::PubSub.new.inherit node
    pubsub.subscriptions.size.must_equal 4
    pubsub.subscriptions.must_equal({
      :subscribed => ['node1', 'node2'],
      :unconfigured => ['node3'],
      :pending => ['node4'],
      :none => ['node5'],
    })
  end
end
