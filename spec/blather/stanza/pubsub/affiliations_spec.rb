require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])
require File.join(File.dirname(__FILE__), *%w[.. .. .. fixtures pubsub])

def control_affiliations
  { :owner => ['node1', 'node2'],
    :publisher => ['node3'],
    :outcast => ['node4'],
    :member => ['node5'],
    :none => ['node6'] }
end

module Blather
  describe 'Blather::Stanza::PubSub::Affiliations' do
    it 'registers itself' do
      XMPPNode.class_from_registration(:affiliations, Stanza::PubSub.registered_ns).must_equal Stanza::PubSub::Affiliations
    end

    it 'can be imported' do
      XMPPNode.import(parse_stanza(affiliations_xml).root).must_be_instance_of Stanza::PubSub::Affiliations
    end

    it 'ensures an affiliations node is present on create' do
      affiliations = Stanza::PubSub::Affiliations.new
      affiliations.find_first('//ns:affiliations', :ns => Stanza::PubSub.registered_ns).wont_be_nil
    end

    it 'ensures an affiliations node exists when calling #affiliations' do
      affiliations = Stanza::PubSub::Affiliations.new
      affiliations.pubsub.remove_children :affiliations
      affiliations.find_first('//ns:affiliations', :ns => Stanza::PubSub.registered_ns).must_be_nil

      affiliations.affiliations.wont_be_nil
      affiliations.find_first('//ns:affiliations', :ns => Stanza::PubSub.registered_ns).wont_be_nil
    end

    it 'defaults to a get node' do
      Stanza::PubSub::Affiliations.new.type.must_equal :get
    end

    it 'sets the host if requested' do
      aff = Stanza::PubSub::Affiliations.new :get, 'pubsub.jabber.local'
      aff.to.must_equal JID.new('pubsub.jabber.local')
    end

    it 'can import an affiliates result node' do
      node = parse_stanza(affiliations_xml).root

      affiliations = Stanza::PubSub::Affiliations.new.inherit node
      affiliations.size.must_equal 5
      affiliations.list.must_equal control_affiliations
    end

    it 'will iterate over each affiliation' do
      XMPPNode.import(parse_stanza(affiliations_xml).root).each do |type, nodes|
        nodes.must_equal control_affiliations[type]
      end
    end
  end
end
