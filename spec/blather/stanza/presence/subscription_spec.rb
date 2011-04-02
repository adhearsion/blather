require 'spec_helper'

describe Blather::Stanza::Presence::Subscription do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:subscription, nil).must_equal Blather::Stanza::Presence::Subscription
  end

  [:subscribe, :subscribed, :unsubscribe, :unsubscribed].each do |type|
    it "must be importable as #{type}" do
      doc = parse_stanza "<presence type='#{type}'/>"
      Blather::XMPPNode.import(doc.root).must_be_instance_of Blather::Stanza::Presence::Subscription
    end
  end

  it 'can set to on creation' do
    sub = Blather::Stanza::Presence::Subscription.new 'a@b'
    sub.to.to_s.must_equal 'a@b'
  end

  it 'can set a type on creation' do
    sub = Blather::Stanza::Presence::Subscription.new nil, :subscribed
    sub.type.must_equal :subscribed
  end

  it 'strips Blather::JIDs when setting #to' do
    sub = Blather::Stanza::Presence::Subscription.new 'a@b/c'
    sub.to.to_s.must_equal 'a@b'
  end

  it 'generates an approval using #approve!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.approve!
    sub.to.must_equal jid
    sub.type.must_equal :subscribed
  end

  it 'generates a refusal using #refuse!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.refuse!
    sub.to.must_equal jid
    sub.type.must_equal :unsubscribed
  end

  it 'generates an unsubscript using #unsubscribe!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.unsubscribe!
    sub.to.must_equal jid
    sub.type.must_equal :unsubscribe
  end

  it 'generates a cancellation using #cancel!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.cancel!
    sub.to.must_equal jid
    sub.type.must_equal :unsubscribed
  end

  it 'generates a request using #request!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.request!
    sub.to.must_equal jid
    sub.type.must_equal :subscribe
  end

  it 'has a #request? helper' do
    sub = Blather::Stanza::Presence::Subscription.new
    sub.must_respond_to :request?
    sub.type = :subscribe
    sub.request?.must_equal true
  end

  it "successfully routes chained actions" do
    from = Blather::JID.new("foo@bar.com")
    to = Blather::JID.new("baz@quux.com")
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = from
    sub.to = to
    sub.cancel!
    sub.unsubscribe!
    sub.type.must_equal :unsubscribe
    sub.to.must_equal from
    sub.from.must_equal to
  end

  it "will inherit only another node's attributes" do
    inheritable = Blather::XMPPNode.new 'foo'
    inheritable[:bar] = 'baz'

    sub = Blather::Stanza::Presence::Subscription.new
    sub.must_respond_to :inherit

    sub.inherit inheritable
    sub[:bar].must_equal 'baz'
  end
end
