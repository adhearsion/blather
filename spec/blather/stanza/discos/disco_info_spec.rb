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
    expect(Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/disco#info')).to eq(Blather::Stanza::Iq::DiscoInfo)
  end

  it 'must be importable' do
    expect(Blather::XMPPNode.parse(disco_info_xml)).to be_instance_of Blather::Stanza::Iq::DiscoInfo
  end

  it 'has a node attribute' do
    n = Blather::Stanza::Iq::DiscoInfo.new nil, 'music', [], []
    expect(n.node).to eq('music')
    n.node = :foo
    expect(n.node).to eq('foo')
  end

  it 'inherits a list of identities' do
    n = parse_stanza disco_info_xml
    r = Blather::Stanza::Iq::DiscoInfo.new.inherit n.root
    expect(r.identities.size).to eq(1)
    expect(r.identities.map { |i| i.class }.uniq).to eq([Blather::Stanza::Iq::DiscoInfo::Identity])
  end

  it 'inherits a list of features' do
    n = parse_stanza disco_info_xml
    r = Blather::Stanza::Iq::DiscoInfo.new.inherit n.root
    expect(r.features.size).to eq(2)
    expect(r.features.map { |i| i.class }.uniq).to eq([Blather::Stanza::Iq::DiscoInfo::Feature])
  end

  it 'is constructed properly' do
    n = Blather::Stanza::Iq::DiscoInfo.new :get, '/path/to/node'
    n.to = 'to@jid.com'
    expect(n.find("/iq[@to='to@jid.com' and @type='get' and @id='#{n.id}']/ns:query[@node='/path/to/node']", :ns => Blather::Stanza::Iq::DiscoInfo.registered_ns)).not_to be_empty
  end

  it 'allows adding of identities' do
    di = Blather::Stanza::Iq::DiscoInfo.new
    expect(di.identities.size).to eq(0)
    di.identities = [{:name => 'name', :type => 'type', :category => 'category'}]
    expect(di.identities.size).to eq(1)
    di.identities += [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]
    expect(di.identities.size).to eq(2)
    di.identities = nil
    expect(di.identities.size).to eq(0)
  end

  it 'allows adding of features' do
    di = Blather::Stanza::Iq::DiscoInfo.new
    expect(di.features.size).to eq(0)
    di.features = ["feature1"]
    expect(di.features.size).to eq(1)
    di.features += [Blather::Stanza::Iq::DiscoInfo::Feature.new("feature2")]
    expect(di.features.size).to eq(2)
    di.features = nil
    expect(di.features.size).to eq(0)
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
    expect(di.identities.size).to eq(2)
    di.identities.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a list of Identity objects as identities' do
    control = [ Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category]),
                Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, control
    expect(di.identities.size).to eq(2)
    di.identities.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a single hash as identity' do
    control = [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, {:name => 'name', :type => 'type', :category => 'category'}
    expect(di.identities.size).to eq(1)
    di.identities.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a single identity object as identity' do
    control = [Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, control.first
    expect(di.identities.size).to eq(1)
    di.identities.each { |i| expect(control.include?(i)).to eq(true) }
  end

  it 'takes a mix of hashes and identity objects as identities' do
    ids = [
      {:name => 'name', :type => 'type', :category => 'category'},
      Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1]),
    ]

    control = [ Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type category]),
                Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name1 type1 category1])]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, ids
    expect(di.identities.size).to eq(2)
    di.identities.each { |i| expect(control.include?(i)).to eq(true) }
  end
end

describe 'Blather::Stanza::Iq::DiscoInfo features' do
  it 'takes a list of features as strings' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], features
    expect(di.features.size).to eq(3)
    di.features.each { |f| expect(control.include?(f)).to eq(true) }
  end

  it 'takes a list of features as Feature objects' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], control
    expect(di.features.size).to eq(3)
    di.features.each { |f| expect(control.include?(f)).to eq(true) }
  end

  it 'takes a single string' do
    control = [Blather::Stanza::Iq::DiscoInfo::Feature.new('feature1')]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], 'feature1'
    expect(di.features.size).to eq(1)
    di.features.each { |f| expect(control.include?(f)).to eq(true) }
  end

  it 'takes a single Feature object' do
    control = [Blather::Stanza::Iq::DiscoInfo::Feature.new('feature1')]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], control.first
    expect(di.features.size).to eq(1)
    di.features.each { |f| expect(control.include?(f)).to eq(true) }
  end

  it 'takes a mixed list of features as Feature objects and strings' do
    features = %w[feature1 feature2 feature3]
    control = features.map { |f| Blather::Stanza::Iq::DiscoInfo::Feature.new f }
    features[1] = control[1]

    di = Blather::Stanza::Iq::DiscoInfo.new nil, nil, [], features
    expect(di.features.size).to eq(3)
    di.features.each { |f| expect(control.include?(f)).to eq(true) }
  end
end

describe Blather::Stanza::Iq::DiscoInfo::Identity do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<identity name='Personal Events' type='pep' category='pubsub' node='publish' xml:lang='en' />"
    i = Blather::Stanza::Iq::DiscoInfo::Identity.new n.root
    expect(i.name).to eq('Personal Events')
    expect(i.type).to eq(:pep)
    expect(i.category).to eq(:pubsub)
    expect(i.xml_lang).to eq('en')
  end

  it 'has a category attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    expect(n.category).to eq(:cat)
    n.category = :foo
    expect(n.category).to eq(:foo)
  end

  it 'has a type attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    expect(n.type).to eq(:type)
    n.type = :foo
    expect(n.type).to eq(:foo)
  end

  it 'has a name attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    expect(n.name).to eq('name')
    n.name = :foo
    expect(n.name).to eq('foo')
  end

  it 'has an xml:lang attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat en])
    expect(n.xml_lang).to eq('en')
    n.xml_lang = 'de'
    expect(n.xml_lang).to eq('de')
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat])
    expect(a).to eq(Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[name type cat]))
    expect(a).not_to equal Blather::Stanza::Iq::DiscoInfo::Identity.new(*%w[not-name not-type not-cat])
  end
end

describe Blather::Stanza::Iq::DiscoInfo::Feature do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<feature var='ipv6' />"
    i = Blather::Stanza::Iq::DiscoInfo::Feature.new n.root
    expect(i.var).to eq('ipv6')
  end

  it 'has a var attribute' do
    n = Blather::Stanza::Iq::DiscoInfo::Feature.new 'var'
    expect(n.var).to eq('var')
    n.var = :foo
    expect(n.var).to eq('foo')
  end

  it 'can determine equality' do
    a = Blather::Stanza::Iq::DiscoInfo::Feature.new('var')
    expect(a).to eq(Blather::Stanza::Iq::DiscoInfo::Feature.new('var'))
    expect(a).not_to equal Blather::Stanza::Iq::DiscoInfo::Feature.new('not-var')
  end
end
