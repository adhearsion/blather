require 'spec_helper'

describe Blather::Stanza::Presence::Subscription do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:subscription, nil).should == Blather::Stanza::Presence::Subscription
  end

  [:subscribe, :subscribed, :unsubscribe, :unsubscribed].each do |type|
    it "must be importable as #{type}" do
      Blather::XMPPNode.parse("<presence type='#{type}'/>").should be_kind_of Blather::Stanza::Presence::Subscription::InstanceMethods
    end
  end

  it 'can set to on creation' do
    sub = Blather::Stanza::Presence::Subscription.new 'a@b'
    sub.to.to_s.should == 'a@b'
  end

  it 'can set a type on creation' do
    sub = Blather::Stanza::Presence::Subscription.new nil, :subscribed
    sub.type.should == :subscribed
  end

  it 'strips Blather::JIDs when setting #to' do
    sub = Blather::Stanza::Presence::Subscription.new 'a@b/c'
    sub.to.to_s.should == 'a@b'
  end

  it 'generates an approval using #approve!' do
    sub = Blather::Stanza.import Nokogiri::XML('<presence from="a@b" type="subscribe"><status/></presence>').root
    sub.approve!
    sub.to.should == 'a@b'
    sub.type.should == :subscribed
  end

  it 'generates a refusal using #refuse!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.refuse!
    sub.to.should == jid
    sub.type.should == :unsubscribed
  end

  it 'generates an unsubscript using #unsubscribe!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.unsubscribe!
    sub.to.should == jid
    sub.type.should == :unsubscribe
  end

  it 'generates a cancellation using #cancel!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.cancel!
    sub.to.should == jid
    sub.type.should == :unsubscribed
  end

  it 'generates a request using #request!' do
    jid = Blather::JID.new 'a@b'
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = jid
    sub.request!
    sub.to.should == jid
    sub.type.should == :subscribe
  end

  it 'has a #request? helper' do
    sub = Blather::Stanza::Presence::Subscription.new
    sub.should respond_to :request?
    sub.type = :subscribe
    sub.request?.should == true
  end

  it "successfully routes chained actions" do
    from = Blather::JID.new("foo@bar.com")
    to = Blather::JID.new("baz@quux.com")
    sub = Blather::Stanza::Presence::Subscription.new
    sub.from = from
    sub.to = to
    sub.cancel!
    sub.unsubscribe!
    sub.type.should == :unsubscribe
    sub.to.should == from
    sub.from.should == to
  end

  it "will inherit only another node's attributes" do
    inheritable = Blather::XMPPNode.new 'foo'
    inheritable[:bar] = 'baz'

    sub = Blather::Stanza::Presence::Subscription.new
    sub.should respond_to :inherit

    sub.inherit inheritable
    sub[:bar].should == 'baz'
  end
end
