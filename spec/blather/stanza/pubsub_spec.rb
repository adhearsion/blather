require File.join(File.dirname(__FILE__), *%w[.. .. spec_helper])

module Blather
  describe 'Blather::Stanza::PubSub' do
    it 'registers itself' do
      XMPPNode.class_from_registration(:pubsub, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub
    end

    it 'ensures a pubusb node is present on create' do
      pubsub = Stanza::PubSub.new
      pubsub.find_first('/iq/pubsub_ns:pubsub', :pubsub_ns => Stanza::PubSub.registered_ns).wont_be_nil
    end

    it 'ensures a pubsub node exists when calling #pubsub' do
      pubsub = Stanza::PubSub.new
      pubsub.remove_children :pubsub
      pubsub.find_first('/iq/pubsub_ns:pubsub', :pubsub_ns => Stanza::PubSub.registered_ns).must_be_nil

      pubsub.pubsub.wont_be_nil
      pubsub.find_first('/iq/pubsub_ns:pubsub', :pubsub_ns => Stanza::PubSub.registered_ns).wont_be_nil
    end

    it 'sets the host if requested' do
      aff = Stanza::PubSub.new :get, 'pubsub.jabber.local'
      aff.to.must_equal JID.new('pubsub.jabber.local')
    end
  end

  describe 'Blather::Stanza::PubSub::Items::PubSubItem' do
    it 'can be initialized with just an ID' do
      id = 'foobarbaz'
      item = Stanza::PubSub::Items::PubSubItem.new id
      item.id.must_equal id
    end

    it 'can be initialized with a payload' do
      payload = 'foobarbaz'
      item = Stanza::PubSub::Items::PubSubItem.new 'foo', payload
      item.payload.must_equal payload
    end

    it 'allows the payload to be set' do
      item = Stanza::PubSub::Items::PubSubItem.new
      item.payload.must_be_nil
      item.payload = 'testing'
      item.payload.must_equal 'testing'
    end

    it 'allows the payload to be unset' do
      payload = 'foobarbaz'
      item = Stanza::PubSub::Items::PubSubItem.new 'foo', payload
      item.payload.must_equal payload
      item.payload = nil
      item.payload.must_be_nil
    end
  end
end
