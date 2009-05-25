require File.join(File.dirname(__FILE__), *%w[.. .. .. spec_helper])

module Blather
  describe 'Blather::Stanza::Presence::Subscription' do
    it 'registers itself' do
      XMPPNode.class_from_registration(:subscription, nil).must_equal Stanza::Presence::Subscription
    end

    it 'can set to on creation' do
      sub = Stanza::Presence::Subscription.new 'a@b'
      sub.to.to_s.must_equal 'a@b'
    end

    it 'can set a type on creation' do
      sub = Stanza::Presence::Subscription.new nil, :subscribed
      sub.type.must_equal :subscribed
    end

    it 'strips JIDs when setting #to' do
      sub = Stanza::Presence::Subscription.new 'a@b/c'
      sub.to.to_s.must_equal 'a@b'
    end

    it 'generates an approval using #approve!' do
      jid = JID.new 'a@b'
      sub = Stanza::Presence::Subscription.new
      sub.from = jid
      sub.approve!
      sub.to.must_equal jid
      sub.type.must_equal :subscribed
    end

    it 'generates a refusal using #refuse!' do
      jid = JID.new 'a@b'
      sub = Stanza::Presence::Subscription.new
      sub.from = jid
      sub.refuse!
      sub.to.must_equal jid
      sub.type.must_equal :unsubscribed
    end

    it 'generates an unsubscript using #unsubscribe!' do
      jid = JID.new 'a@b'
      sub = Stanza::Presence::Subscription.new
      sub.from = jid
      sub.unsubscribe!
      sub.to.must_equal jid
      sub.type.must_equal :unsubscribe
    end

    it 'generates a cancellation using #cancel!' do
      jid = JID.new 'a@b'
      sub = Stanza::Presence::Subscription.new
      sub.from = jid
      sub.cancel!
      sub.to.must_equal jid
      sub.type.must_equal :unsubscribed
    end

    it 'generates a request using #request!' do
      jid = JID.new 'a@b'
      sub = Stanza::Presence::Subscription.new
      sub.from = jid
      sub.request!
      sub.to.must_equal jid
      sub.type.must_equal :subscribe
    end

    it 'has a #request? helper' do
      sub = Stanza::Presence::Subscription.new
      sub.must_respond_to :request?
      sub.type = :subscribe
      sub.request?.must_equal true
    end

    it "will inherit only another node's attributes" do
      inheritable = XMPPNode.new 'foo'
      inheritable[:bar] = 'baz'

      sub = Stanza::Presence::Subscription.new
      sub.must_respond_to :inherit

      sub.inherit inheritable
      sub[:bar].must_equal 'baz'
    end
  end
end
