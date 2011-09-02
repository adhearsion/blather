require 'spec_helper'

def muc_owner_xml
  <<-XML
  <iq from='romeo@montague.net/orchard'
      to='5567@conference.jabber.org'
      type='set'>
    <query xmlns='http://jabber.org/protocol/muc#owner'>
      <x xmlns='jabber:x:data' type='submit'>
        <field var='FORM_TYPE'>
          <value>http://jabber.org/protocol/muc#roomconfig</value>
        </field>
        <field var='muc#roomconfig_moderatedroom'>
          <value>1</value>
        </field>
      </x>
    </query>
  </iq>
  XML
end

describe Blather::Stanza::Iq::MUC::Owner do
  it 'registers itself' do
    Blather::XMPPNode.class_from_registration(:query, 'http://jabber.org/protocol/muc#owner').must_equal Blather::Stanza::Iq::MUC::Owner
  end

  it 'must be importable' do
    Blather::XMPPNode.import(parse_stanza(muc_owner_xml).root).must_be_instance_of Blather::Stanza::Iq::MUC::Owner
  end

  [:get, :set, :result, :error].each do |type|
    it "can be set as \"#{type}\"" do
      c = Blather::Stanza::Iq::MUC::Owner.new type
      c.type.must_equal type
    end
  end

  it 'sets type to "result" on reply' do
    c = Blather::Stanza::Iq::MUC::Owner.new
    c.type.must_equal :get
    c.reply.type.must_equal :result
  end

  it 'sets type to "result" on reply!' do
    c = Blather::Stanza::Iq::MUC::Owner.new
    c.type.must_equal :get
    c.reply!
    c.type.must_equal :result
  end

  it 'makes a form child available' do
    n = Blather::XMPPNode.import(parse_stanza(muc_owner_xml).root)
    n.form.fields.size.must_equal 2
    n.form.fields.map { |f| f.class }.uniq.must_equal [Blather::Stanza::X::Field]
    n.form.must_be_instance_of Blather::Stanza::X

    r = Blather::Stanza::Iq::MUC::Owner.new
    r.form.type = :form
    r.form.type.must_equal :form
  end

  it 'ensures a form node exists when calling #form' do
    c = Blather::Stanza::Iq::MUC::Owner.new
    c.query.remove_children :x
    c.xpath('ns:query/ns2:x', :ns => Blather::Stanza::Iq::MUC::Owner.registered_ns, :ns2 => Blather::Stanza::X.registered_ns).must_be_empty

    c.form.wont_be_nil
    c.xpath('ns:query/ns2:x', :ns => Blather::Stanza::Iq::MUC::Owner.registered_ns, :ns2 => Blather::Stanza::X.registered_ns).wont_be_empty
  end
end
