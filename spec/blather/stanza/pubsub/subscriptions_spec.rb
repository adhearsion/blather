require 'spec_helper'
require 'fixtures/pubsub'

def control_subscriptions
  { :subscribed => [{:node => 'node1', :jid => 'francisco@denmark.lit', :subid => 'fd8237yr872h3f289j2'}, {:node => 'node2', :jid => 'francisco@denmark.lit', :subid => 'h8394hf8923ju'}],
    :unconfigured => [{:node => 'node3', :jid => 'francisco@denmark.lit'}],
    :pending => [{:node => 'node4', :jid => 'francisco@denmark.lit'}],
    :none => [{:node => 'node5', :jid => 'francisco@denmark.lit'}] }
end

describe Blather::Stanza::PubSub::Subscriptions do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:subscriptions, 'http://jabber.org/protocol/pubsub').should == Blather::Stanza::PubSub::Subscriptions
  end

  it 'can be imported' do
    Blather::XMPPNode.parse(subscriptions_xml).should be_instance_of Blather::Stanza::PubSub::Subscriptions
  end

  it 'ensures an subscriptions node is present on create' do
    subscriptions = Blather::Stanza::PubSub::Subscriptions.new
    subscriptions.xpath('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'ensures an subscriptions node exists when calling #subscriptions' do
    subscriptions = Blather::Stanza::PubSub::Subscriptions.new
    subscriptions.pubsub.remove_children :subscriptions
    subscriptions.xpath('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).should be_empty

    subscriptions.subscriptions.should_not be_nil
    subscriptions.xpath('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).should_not be_empty
  end

  it 'defaults to a get node' do
    aff = Blather::Stanza::PubSub::Subscriptions.new
    aff.type.should == :get
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSub::Subscriptions.new :get, 'pubsub.jabber.local'
    aff.to.should == Blather::JID.new('pubsub.jabber.local')
  end

  it 'can import a subscriptions result node' do
    node = parse_stanza(subscriptions_xml).root

    subscriptions = Blather::Stanza::PubSub::Subscriptions.new.inherit node
    subscriptions.size.should == 4
    subscriptions.list.should == control_subscriptions
  end

  it 'will iterate over each subscription' do
    node = parse_stanza(subscriptions_xml).root
    subscriptions = Blather::Stanza::PubSub::Subscriptions.new.inherit node
    subscriptions.each do |type, nodes|
      nodes.should == control_subscriptions[type]
    end
  end
end
