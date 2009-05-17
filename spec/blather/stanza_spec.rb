require File.join(File.dirname(__FILE__), *%w[.. spec_helper])

module Blather
  describe 'Blather::Stanza' do
    it 'provides .next_id helper for generating new IDs' do
      proc { Blather::Stanza.next_id }.must_change 'Blather::Stanza.next_id'
    end

    it 'can import a node' do
      s = Stanza.import XMPPNode.new('foo')
      s.element_name.must_equal 'foo'
    end

    it 'sets the ID when created' do
      Stanza.new('message').id.wont_be_nil
    end

    it 'sets the document when created' do
      Stanza.new('message').doc.wont_be_nil
    end

    it 'provides an #error? helper' do
      s = Stanza.new('message')
      s.error?.must_equal false
      s.type = :error
      s.error?.must_equal true
    end

    it 'will generate a reply' do
      s = Stanza.new('message')
      s.from = f = JID.new('n@d/r')
      s.to = t = JID.new('d@n/r')

      r = s.reply
      r.object_id.wont_equal s.object_id
      r.from.must_equal t
      r.to.must_equal f
    end

    it 'convert to a reply' do
      s = Stanza.new('message')
      s.from = f = JID.new('n@d/r')
      s.to = t = JID.new('d@n/r')

      r = s.reply!
      r.object_id.must_equal s.object_id
      r.from.must_equal t
      r.to.must_equal f
    end

    it 'provides "attr_accessor" for id' do
      s = Stanza.new('message')
      s.id.wont_be_nil
      s['id'].wont_be_nil

      s.id = nil
      s.id.must_be_nil
      s['id'].must_be_nil
    end

    it 'provides "attr_accessor" for to' do
      s = Stanza.new('message')
      s.to.must_be_nil
      s['to'].must_be_nil

      s.to = JID.new('n@d/r')
      s.to.wont_be_nil
      s.to.must_be_kind_of JID

      s['to'].wont_be_nil
      s['to'].must_equal 'n@d/r'
    end

    it 'provides "attr_accessor" for from' do
      s = Stanza.new('message')
      s.from.must_be_nil
      s['from'].must_be_nil

      s.from = JID.new('n@d/r')
      s.from.wont_be_nil
      s.from.must_be_kind_of JID

      s['from'].wont_be_nil
      s['from'].must_equal 'n@d/r'
    end

    it 'provides "attr_accessor" for type' do
      s = Stanza.new('message')
      s.type.must_be_nil
      s['type'].must_be_nil

      s.type = 'testing'
      s.type.wont_be_nil
      s['type'].wont_be_nil
    end

    it 'can be converted into an error by error name' do
      s = Stanza.new('message')
      err = s.as_error 'internal-server-error', 'cancel'
      err.name.must_equal :internal_server_error
    end
  end
end
