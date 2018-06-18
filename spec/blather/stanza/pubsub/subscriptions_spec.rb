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
    expect(Blather::XMPPNode.class_from_registration(:subscriptions, 'http://jabber.org/protocol/pubsub')).to eq(Blather::Stanza::PubSub::Subscriptions)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(subscriptions_xml)).to be_instance_of Blather::Stanza::PubSub::Subscriptions
  end

  it 'ensures an subscriptions node is present on create' do
    subscriptions = Blather::Stanza::PubSub::Subscriptions.new
    expect(subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures an subscriptions node exists when calling #subscriptions' do
    subscriptions = Blather::Stanza::PubSub::Subscriptions.new
    subscriptions.pubsub.remove_children :subscriptions
    expect(subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    expect(subscriptions.subscriptions).not_to be_nil
    expect(subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_empty
  end

  it 'ensures the subscriptions node is not duplicated when calling #subscriptions' do
    subscriptions = Blather::Stanza::PubSub::Subscriptions.new
    subscriptions.pubsub.remove_children :subscriptions
    expect(subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns)).to be_empty

    5.times { subscriptions.subscriptions }
    expect(subscriptions.find('//ns:pubsub/ns:subscriptions', :ns => Blather::Stanza::PubSub.registered_ns).count).to eq(1)
  end

  it 'defaults to a get node' do
    aff = Blather::Stanza::PubSub::Subscriptions.new
    expect(aff.type).to eq(:get)
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSub::Subscriptions.new :get, 'pubsub.jabber.local'
    expect(aff.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'can import a subscriptions result node' do
    node = parse_stanza(subscriptions_xml).root

    subscriptions = Blather::Stanza::PubSub::Subscriptions.new.inherit node
    expect(subscriptions.size).to eq(4)
    expect(subscriptions.list).to eq(control_subscriptions)
  end

  it 'will iterate over each subscription' do
    node = parse_stanza(subscriptions_xml).root
    subscriptions = Blather::Stanza::PubSub::Subscriptions.new.inherit node
    subscriptions.each do |type, nodes|
      expect(nodes).to eq(control_subscriptions[type])
    end
  end
end
