require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

describe Blather::Stanza::PubSub::Retract do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:retract, 'http://jabber.org/protocol/pubsub').must_equal Blather::Stanza::PubSub::Retract
  end

  it 'can be imported' do
    Blather::XMPPNode.import(parse_stanza(retract_xml).root).must_be_instance_of Blather::Stanza::PubSub::Retract
  end

  it 'ensures an retract node is present on create' do
    retract = Blather::Stanza::PubSub::Retract.new
    retract.find('//ns:pubsub/ns:retract', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'ensures an retract node exists when calling #retract' do
    retract = Blather::Stanza::PubSub::Retract.new
    retract.pubsub.remove_children :retract
    retract.find('//ns:pubsub/ns:retract', :ns => Blather::Stanza::PubSub.registered_ns).must_be_empty

    retract.retract.wont_be_nil
    retract.find('//ns:pubsub/ns:retract', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'defaults to a set node' do
    retract = Blather::Stanza::PubSub::Retract.new
    retract.type.must_equal :set
  end

  it 'sets the host if requested' do
    retract = Blather::Stanza::PubSub::Retract.new 'pubsub.jabber.local'
    retract.to.must_equal Blather::JID.new('pubsub.jabber.local')
  end

  it 'sets the node' do
    retract = Blather::Stanza::PubSub::Retract.new 'host', 'node-name'
    retract.node.must_equal 'node-name'
  end

  it 'can set the retractions as a string' do
    retract = Blather::Stanza::PubSub::Retract.new 'host', 'node'
    retract.retractions = 'id1'
    retract.xpath('//ns:retract[ns:item[@id="id1"]]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'can set the retractions as an array' do
    retract = Blather::Stanza::PubSub::Retract.new 'host', 'node'
    retract.retractions = %w[id1 id2]
    retract.xpath('//ns:retract[ns:item[@id="id1"] and ns:item[@id="id2"]]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

  it 'will iterate over each item' do
    retract = Blather::Stanza::PubSub::Retract.new.inherit parse_stanza(retract_xml).root
    retract.retractions.size.must_equal 1
    retract.retractions.must_equal %w[ae890ac52d0df67ed7cfdf51b644e901]
  end

  it 'has a node attribute' do
    retract = Blather::Stanza::PubSub::Retract.new
    retract.must_respond_to :node
    retract.node.must_be_nil
    retract.node = 'node-name'
    retract.node.must_equal 'node-name'
    retract.xpath('//ns:retract[@node="node-name"]', :ns => Blather::Stanza::PubSub.registered_ns).wont_be_empty
  end

end
