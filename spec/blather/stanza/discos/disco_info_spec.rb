require 'spec_helper'

def disco_info_xml
  <<-XML
  <iq type='result'
      from='romeo@montague.net/orchard'
      to='juliet@capulet.com/balcony'
      id='info4'>
    <query xmlns='http://jabber.org/protocol/disco#info'>
      <identity
          category='client'
          type='pc'
          name='Gabber'
          xml:lang='en'/>
      <feature var='jabber:iq:time'/>
      <feature var='jabber:iq:version'/>
    </query>
  </iq>
  XML
end

describe Blather::Stanza::Iq::DiscoInfo do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/disco#info').should == Blather::Stanza::Iq::DiscoInfo
  end

  it 'must be importable' do
    Blather::XMPPNode.parse(disco_info_xml).should be_instance_of Blather::Stanza::Iq::DiscoInfo
  end

  it 'has a node attribute' do
    n = Blather::Stanza::Iq::DiscoInfo.new nil, 'music', [], []
    n.node.should == 'music'
    n.node = :foo
    n.node.should == 'foo'
  end

  it 'inherits a list of identities' do
    n = parse_stanza disco_info_xml
    r = Blather::Stanza::Iq::DiscoInfo.new.inherit n.root
    r.identities.size.should == 1
    r.identities.map { |i| i.class }.uniq.should == [Blather::Stanza::Iq::DiscoInfo::Identity]
  end

  it 'inherits a list of features' do
    n = parse_stanza disco_info_xml
    r = Blather::Stanza::Iq::DiscoInfo.new.inherit n.root
    r.features.size.should == 2
    r.features.map { |i| i.class }.uniq.should == [Blather::Stanza::Iq::DiscoInfo::Feature]
  end

  it 'is constructed properly' do
    n = Blather::Stanza::Iq::DiscoInfo.new :get, '/path/to/node'
    n.to = 'to@jid.com'
    n.find("/iq[@to='to@jid.com' and @type='get' and @id='#{n.id}']/ns:query[@node='/path/to/node']", :ns => Blather::Stanza::Iq::DiscoInfo.registered_ns).should_not be_empty
  end

  it 'allows adding of identities' do
    di = Blather::Stanza::Iq::DiscoInfo.new
    di.identities.size.should == 0
    di.identities = [{:name => 'name', :type => 'type', :category => 'category'}]
    di.identities.size.should == 1
    di.identities += [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]
    di.identities.size.should == 2
    di.identities = nil
    di.identities.size.should == 0
  end

  it 'allows adding of features' do
    di = Blather::Stanza::Iq::DiscoInfo.new
    di.features.size.should == 0
    di.features = ["feature1"]
    di.features.size.should == 1
    di.features += [Blather::Stanza::Iq::DiscoInfo::Feature.new("feature2")]
    di.features.size.should == 2
    di.features = nil
    di.features.size.should == 0
  end

end

describe 'Blather::Stanza::Iq::DiscoInfo identities' do
  it 'takes a list of hashes for identities' do
    ids = [
      {:name => 'name', :type => 'type', :category => 'category'},
      {:name => 'name1', :type => 'type1', :category => 'category1'},
    ]

    control = [ Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category]),
                Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, ids
    di.identities.size.should == 2
    di.identities.each { |i| control.include?(i).should == true }
  end

  it 'takes a list of Identity objects as identities' do
    control = [ Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category]),
                Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, control
    di.identities.size.should == 2
    di.identities.each { |i| control.include?(i).should == true }
  end

  it 'takes a single hash as identity' do
    control = [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, {:name => 'name', :type => 'type', :category => 'category'}
    di.identities.size.should == 1
    di.identities.each { |i| control.include?(i).should == true }
  end

  it 'takes a single identity object as identity' do
    control = [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, control.first
    di.identities.size.should == 1
    di.identities.each { |i| control.include?(i).should == true }
  end

  it 'takes a mix of hashes and identity objects as identities' do
    ids = [
      {:name => 'name', :type => 'type', :category => 'category'},
      Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1]),
    ]

    control = [ Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category]),
                Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, ids
    di.identities.size.should == 2
    di.identities.each { |i| control.include?(i).should == true }
  end
end

describe 'Blather::Stanza::Iq::DiscoInfo features' do
  it 'takes a list of features as strings' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], features
    di.features.size.should == 3
    di.features.each { |f| control.include?(f).should == true }
  end

  it 'takes a list of features as Feature objects' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], control
    di.features.size.should == 3
    di.features.each { |f| control.include?(f).should == true }
  end

  it 'takes a single string' do
    control = [Blather::Stanza::Iq::DiscoInfo::Feature.new('feature1')]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], 'feature1'
    di.features.size.should == 1
    di.features.each { |f| control.include?(f).should == true }
  end

  it 'takes a single Feature object' do
    control = [Blather::Stanza::Iq::DiscoInfo::Feature.new('feature1')]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], control.first
    di.features.size.should == 1
    di.features.each { |f| control.include?(f).should == true }
  end

  it 'takes a mixed list of features as Feature objects and strings' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }
    features[1] = control[1]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], features
    di.features.size.should == 3
    di.features.each { |f| control.include?(f).should == true }
  end
end

describe Blather::Stanza::Iq::DiscoInfo::Identity do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<identity name='Personal Events' type='pep' category='pubsub' node='publish' xml:lang='en' />"
    i = Blather::Stanza::Iq::DiscoInfo::Identity.new n.root
    i.name.should == 'Personal Events'
    i.type.should == :pep
    i.category.should == :pubsub
    i.xml_lang.should == 'en'
  end

  it 'has a category attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    n.category.should == :cat
    n.category = :foo
    n.category.should == :foo
  end

  it 'has a type attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    n.type.should == :type
    n.type = :foo
    n.type.should == :foo
  end

  it 'has a name attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    n.name.should == 'name'
    n.name = :foo
    n.name.should == 'foo'
  end

  it 'has an xml:lang attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat en])
    n.xml_lang.should == 'en'
    n.xml_lang = 'de'
    n.xml_lang.should == 'de'
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    a.should == Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    a.should_not equal Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[not-name not-type not-cat])
  end
end

describe Blather::Stanza::Iq::DiscoInfo::Feature do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<feature var='ipv6' />"
    i = Blather::Stanza::Iq::DiscoInfo::Feature.new n.root
    i.var.should == 'ipv6'
  end

  it 'has a var attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Feature.new 'var'
    n.var.should == 'var'
    n.var = :foo
    n.var.should == 'foo'
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoInfo::Feature.new('var')
    a.should == Blather::Stanza::Iq::DiscoInfo::Feature.new('var')
    a.should_not equal Blather::Stanza::Iq::DiscoInfo::Feature.new('not-var')
  end
end
