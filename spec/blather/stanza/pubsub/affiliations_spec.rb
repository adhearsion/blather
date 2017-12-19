require 'spec_helper'
require 'fixtures/pubsub'

def control_affiliations
  { :owner => ['node1', 'node2'],
    :publisher => ['node3'],
    :outcast => ['node4'],
    :member => ['node5'],
    :none => ['node6'] }
end

describe Blather::Stanza::PubSub::Affiliations do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:affiliations, Blather::Stanza::PubSub.registered_ns)).to eq(Blather::Stanza::PubSub::Affiliations)
  end

  it 'can be imported' do
    expect(Blather::XMPPNode.parse(affiliations_xml)).to be_instance_of Blather::Stanza::PubSub::Affiliations
  end

  it 'ensures an affiliations node is present on create' do
    affiliations = Blather::Stanza::PubSub::Affiliations.new
    expect(affiliations.find_first('//ns:affiliations', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_nil
  end

  it 'ensures an affiliations node exists when calling #affiliations' do
    affiliations = Blather::Stanza::PubSub::Affiliations.new
    affiliations.pubsub.remove_children :affiliations
    expect(affiliations.find_first('//ns:affiliations', :ns => Blather::Stanza::PubSub.registered_ns)).to be_nil

    expect(affiliations.affiliations).not_to be_nil
    expect(affiliations.find_first('//ns:affiliations', :ns => Blather::Stanza::PubSub.registered_ns)).not_to be_nil
  end

  it 'defaults to a get node' do
    expect(Blather::Stanza::PubSub::Affiliations.new.type).to eq(:get)
  end

  it 'sets the host if requested' do
    aff = Blather::Stanza::PubSub::Affiliations.new :get, 'pubsub.jabber.local'
    expect(aff.to).to eq(Blather::JID.new('pubsub.jabber.local'))
  end

  it 'can import an affiliates result node' do
    node = parse_stanza(affiliations_xml).root

    affiliations = Blather::Stanza::PubSub::Affiliations.new.inherit node
    expect(affiliations.size).to eq(5)
    expect(affiliations.list).to eq(control_affiliations)
  end

  it 'will iterate over each affiliation' do
    Blather::XMPPNode.parse(affiliations_xml).each do |type, nodes|
      expect(nodes).to eq(control_affiliations[type])
    end
  end
end
