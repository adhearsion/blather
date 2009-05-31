require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

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
          name='Gabber'/>
      <feature var='jabber:iq:time'/>
      <feature var='jabber:iq:version'/>
    </query>
  </iq>
  XML
end

describe Blather::Stanza::Iq::DiscoInfo do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/disco#info').must_equal Blather::Stanza::Iq::DiscoInfo
  end

  it 'must be importable' do
    doc = parse_stanza disco_info_xml
    Blather::XMPPNode.import(doc.root).must_be_instance_of Blather::Stanza::Iq::DiscoInfo
  end

  it 'has a node attribute' do
    n = Blather::Stanza::Iq::DiscoInfo.new nil, 'music', [], []
    n.node.must_equal 'music'
    n.node = :foo
    n.node.must_equal 'foo'
  end

  it 'inherits a list of identities' do
    n = parse_stanza disco_info_xml
    r = Blather::Stanza::Iq::DiscoInfo.new.inherit n.root
    r.identities.size.must_equal 1
    r.identities.map { |i| i.class }.uniq.must_equal [Blather::Stanza::Iq::DiscoInfo::Identity]
  end
  it 'inherits a list of features' do
    n = parse_stanza disco_info_xml
    r = Blather::Stanza::Iq::DiscoInfo.new.inherit n.root
    r.features.size.must_equal 2
    r.features.map { |i| i.class }.uniq.must_equal [Blather::Stanza::Iq::DiscoInfo::Feature]
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
    di.identities.size.must_equal 2
    di.identities.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a list of Identity objects as identities' do
    control = [ Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category]),
                Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, control
    di.identities.size.must_equal 2
    di.identities.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a single hash as identity' do
    control = [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, {:name => 'name', :type => 'type', :category => 'category'}
    di.identities.size.must_equal 1
    di.identities.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a single identity object as identity' do
    control = [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, control.first
    di.identities.size.must_equal 1
    di.identities.each { |i| control.include?(i).must_equal true }
  end

  it 'takes a mix of hashes and identity objects as identities' do
    ids = [
      {:name => 'name', :type => 'type', :category => 'category'},
      Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1]),
    ]

    control = [ Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category]),
                Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, ids
    di.identities.size.must_equal 2
    di.identities.each { |i| control.include?(i).must_equal true }
  end
end

describe 'Blather::Stanza::Iq::DiscoInfo features' do
  it 'takes a list of features as strings' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], features
    di.features.size.must_equal 3
    di.features.each { |f| control.include?(f).must_equal true }
  end

  it 'takes a list of features as Feature objects' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], control
    di.features.size.must_equal 3
    di.features.each { |f| control.include?(f).must_equal true }
  end

  it 'takes a single string' do
    control = [Blather::Stanza::Iq::DiscoInfo::Feature.new('feature1')]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], 'feature1'
    di.features.size.must_equal 1
    di.features.each { |f| control.include?(f).must_equal true }
  end

  it 'takes a single Feature object' do
    control = [Blather::Stanza::Iq::DiscoInfo::Feature.new('feature1')]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], control.first
    di.features.size.must_equal 1
    di.features.each { |f| control.include?(f).must_equal true }
  end

  it 'takes a mixed list of features as Feature objects and strings' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }
    features[1] = control[1]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], features
    di.features.size.must_equal 3
    di.features.each { |f| control.include?(f).must_equal true }
  end
end

describe Blather::Stanza::Iq::DiscoInfo::Identity do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<identity name='Personal Events' type='pep' category='pubsub' node='publish' />"
    i = Blather::Stanza::Iq::DiscoInfo::Identity.new n.root
    i.name.must_equal 'Personal Events'
    i.type.must_equal :pep
    i.category.must_equal :pubsub
  end

  it 'has a category attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    n.category.must_equal :cat
    n.category = :foo
    n.category.must_equal :foo
  end

  it 'has a type attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    n.type.must_equal :type
    n.type = :foo
    n.type.must_equal :foo
  end

  it 'has a name attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    n.name.must_equal 'name'
    n.name = :foo
    n.name.must_equal 'foo'
  end

  it 'raises an error if equality is sent a non DiscoInfo::Identity object' do
    a = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    lambda { a == 'foo' }.must_raise RuntimeError
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    a.must_equal Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    a.wont_equal Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[not-name not-type not-cat])
  end
end

describe Blather::Stanza::Iq::DiscoInfo::Feature do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<feature var='ipv6' />"
    i = Blather::Stanza::Iq::DiscoInfo::Feature.new n.root
    i.var.must_equal 'ipv6'
  end

  it 'has a var attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Feature.new 'var'
    n.var.must_equal 'var'
    n.var = :foo
    n.var.must_equal 'foo'
  end

  it 'raises an error if equality is sent a non DiscoInfo::Feature object' do
    a = Blather::Stanza::Iq::DiscoInfo::Feature.new('var')
    lambda { a == 'foo' }.must_raise RuntimeError
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoInfo::Feature.new('var')
    a.must_equal Blather::Stanza::Iq::DiscoInfo::Feature.new('var')
    a.wont_equal Blather::Stanza::Iq::DiscoInfo::Feature.new('not-var')
  end
end
