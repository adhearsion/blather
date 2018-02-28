require 'spec_helper'

describe Blather::Stanza::Presence::Subscription do
  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:subscription, nil)).to eq(Blather::Stanza::Presence::Subscription)
  end

  [:subscribe, :subscribed, :unsubscribe, :unsubscribed].each do |type|
    it "must be importable as #{type}" do
      expect(Blather::XMPPNode.parse("<presence type='#{type}'/>")).to be_kind_of Blather::Stanza::Presence::Subscription::InstanceMethods
    end
  end

  it 'can set to on creation' do
    sub = Blather::Stanza::Presence::Subscription.new 'a@b'
    expect(sub.to.to_s).to eq('a@b')
  end

  it 'can set a type on creation' do
    sub = Blather::Stanza::Presence::Subscription.new nil, :subscribed
    expect(sub.type).to eq(:subscribed)
  end

  it 'strips Blather::JIDs when setting #to' do
    sub = Blather::Stanza::Presence::Subscription.new 'a@b/c'
    expect(sub.to.to_s).to eq('a@b')
  end

  it 'generates an approval using #approve!' do
    sub = Blather::Stanza.import Nokogiri::XML('<presence from="a@b" type="subscribe"><status/></presence>').root
    sub.approve!
    expect(sub.to).to eq('a@b')
    expect(sub.type).to eq(:subscribed)
  end

  it 'generates a refusal using #refuse!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.refuse!
    expect(sub.to).to eq(jid)
    expect(sub.type).to eq(:unsubscribed)
  end

  it 'generates an unsubscript using #unsubscribe!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.unsubscribe!
    expect(sub.to).to eq(jid)
    expect(sub.type).to eq(:unsubscribe)
  end

  it 'generates a cancellation using #cancel!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.cancel!
    expect(sub.to).to eq(jid)
    expect(sub.type).to eq(:unsubscribed)
  end

  it 'generates a request using #request!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.request!
    expect(sub.to).to eq(jid)
    expect(sub.type).to eq(:subscribe)
  end

  it 'has a #request? helper' do
    sub = Blather::Stanza::Presence::Subscription.new
    expect(sub).to respond_to :request?
    sub.type = :subscribe
    expect(sub.request?).to eq(true)
  end

  it "successfully routes chained actions" do
    from = Blather::JID.new("foo@bar.com")
    to = Blather::JID.new("baz@quux.com")
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = from
    sub.to = to
    sub.cancel!
    sub.unsubscribe!
    expect(sub.type).to eq(:unsubscribe)
    expect(sub.to).to eq(from)
    expect(sub.from).to eq(to)
  end

  it "will inherit only another node's attributes" do
    inheritable = Blather::XMPPNode.new 'foo'
    inheritable[:bar] = 'baz'

    sub = Blather::Stanza::Presence::Subscription.new
    expect(sub).to respond_to :inherit

    sub.inherit inheritable
    expect(sub[:bar]).to eq('baz')
  end
end
