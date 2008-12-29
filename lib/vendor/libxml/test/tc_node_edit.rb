require 'xml'
require 'test/unit'

class TestNodeEdit < Test::Unit::TestCase
  def setup
    xp = XML::Parser.new()
    xp.string = '<test><num>one</num><num>two</num><num>three</num></test>'
    @doc = xp.parse
  end

  def teardown
    @doc = nil
  end
  
  def first_node
    @doc.root.child
  end
  
  def second_node
    first_node.next
  end
  
  def third_node
    second_node.next
  end
 
  def test_add_next_01
    first_node.next = XML::Node.new('num', 'one-and-a-half')
    assert_equal('<test><num>one</num><num>one-and-a-half</num><num>two</num><num>three</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  def test_add_next_02
    second_node.next = XML::Node.new('num', 'two-and-a-half')
    assert_equal('<test><num>one</num><num>two</num><num>two-and-a-half</num><num>three</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  def test_add_next_03
    third_node.next = XML::Node.new('num', 'four')
    assert_equal '<test><num>one</num><num>two</num><num>three</num><num>four</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end

  def test_add_prev_01
    first_node.prev = XML::Node.new('num', 'half')
    assert_equal '<test><num>half</num><num>one</num><num>two</num><num>three</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end

  def test_add_prev_02
    second_node.prev = XML::Node.new('num', 'one-and-a-half')
    assert_equal '<test><num>one</num><num>one-and-a-half</num><num>two</num><num>three</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end

  def test_add_prev_03
    third_node.prev = XML::Node.new('num', 'two-and-a-half')
    assert_equal '<test><num>one</num><num>two</num><num>two-and-a-half</num><num>three</num></test>',
      @doc.root.to_s.gsub(/\n\s*/,'')
  end
  
  def test_remove_node
    first_node.remove!
    assert_equal('<test><num>two</num><num>three</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  def test_reuse_removed_node
    # Remove the node
    node = @doc.root.first.remove!
    assert_not_nil(node)

    # Add it to the end of the documnet
    @doc.root.last.next = node

    assert_equal('<test><num>two</num><num>three</num><num>one</num></test>',
                 @doc.root.to_s.gsub(/\n\s*/,''))
  end

  # This test is to verify that an earlier reported bug has been fixed  
  def test_merge
    documents = []

    # Read in 500 documents
    500.times do
      documents << XML::Parser.string(File.read(File.join(File.dirname(__FILE__), 'model', 'merge_bug_data.xml'))).parse
    end

    master_doc = documents.shift
    documents.inject(master_doc) do |master_doc, child_doc|
      master_body = master_doc.find("//body").first
      child_body = child_doc.find("//body").first
      
      child_element = child_body.detect do |node|
        node.element?
      end
      
      master_body << child_element.copy(true)
      master_doc
    end
  end
  
  def test_append_chain
    node = XML::Node.new('foo') << XML::Node.new('bar') << "bars contents"
    assert_equal('<foo><bar/>bars contents</foo>',
                 node.to_s)
  end

  def test_set_base
    @doc.root.base = 'http://www.rubynet.org/'
    assert_equal("<test xml:base=\"http://www.rubynet.org/\">\n  <num>one</num>\n  <num>two</num>\n  <num>three</num>\n</test>",
                 @doc.root.to_s)
  end
end
