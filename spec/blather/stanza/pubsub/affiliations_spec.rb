require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

def affiliations_xml
  <<-NODE
    <iq type='result'
        from='pubsub.shakespeare.lit'
        to='francisco@denmark.lit'
        id='affil1'>
      <pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <affiliations>
          <affiliation node='node1' affiliation='owner'/>
          <affiliation node='node2' affiliation='owner'/>
          <affiliation node='node3' affiliation='publisher'/>
          <affiliation node='node4' affiliation='outcast'/>
          <affiliation node='node5' affiliation='member'/>
          <affiliation node='node6' affiliation='none'/>
        </affiliations>
      </pubsub>
    </iq>
  NODE
end

describe 'Blather::Stanza::PubSub::Affiliations' do
  it 'registers itself' do
    XMPPNode.class_from_registration(:pubsub_affiliations, 'http://jabber.org/protocol/pubsub').must_equal Stanza::PubSub::Affiliations
  end

  it 'ensures an affiliations node is present on create' do
    affiliations = Stanza::PubSub::Affiliations.new
    affiliations.pubsub.children.detect { |n| n.element_name == 'affiliations' }.wont_be_nil
  end

  it 'ensures an affiliations node exists when calling #affiliations' do
    affiliations = Stanza::PubSub::Affiliations.new
    affiliations.pubsub.remove_child :affiliations
    affiliations.pubsub.children.detect { |n| n.element_name == 'affiliations' }.must_be_nil

    affiliations.list.wont_be_nil
    affiliations.pubsub.children.detect { |n| n.element_name == 'affiliations' }.wont_be_nil    
  end

  it 'defaults to a get node' do
    aff = Stanza::PubSub::Affiliations.new
    aff.type.must_equal :get
  end

  it 'sets the host if requested' do
    aff = Stanza::PubSub::Affiliations.new :get, 'pubsub.jabber.local'
    aff.to.must_equal JID.new('pubsub.jabber.local')
  end

  it 'can import an affiliates result node' do
    node = XML::Document.string(affiliations_xml).root

    affiliations = Stanza::PubSub::Affiliations.new.inherit node
    affiliations.size.must_equal 5
    affiliations.list.must_equal({
      :owner => ['node1', 'node2'],
      :publisher => ['node3'],
      :outcast => ['node4'],
      :member => ['node5'],
      :none => ['node6']
    })
  end
end
