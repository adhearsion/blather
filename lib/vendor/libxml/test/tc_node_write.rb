require 'xml'
require 'test/unit'

class TestNodeWrite < Test::Unit::TestCase
  def setup
    # Strip spaces to make testing easier
    XML.default_keep_blanks = false
    file = File.join(File.dirname(__FILE__), 'model/bands.xml')
    @doc = XML::Document.file(file)
  end
  
  def teardown
    XML.default_keep_blanks = true
    @doc = nil
  end
  
  def test_to_s_default
    # Default to_s has indentation
    node = @doc.root
    assert_equal("<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 node.to_s)
  end

  def test_to_s_no_global_indentation
    # No indentation due to global setting
    node = @doc.root
    XML.indent_tree_output = false
    assert_equal("<bands genre=\"metal\">\n<m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n<iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 node.to_s)
  ensure
    XML.indent_tree_output = true
  end

  def test_to_s_no_indentation
    # No indentation due to local setting
    node = @doc.root
    assert_equal("<bands genre=\"metal\"><m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e><iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden></bands>",
                 node.to_s(:indent => false))
  end

  def test_to_s_level
    # No indentation due to local setting
    node = @doc.root
    assert_equal("<bands genre=\"metal\">\n    <m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n    <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n  </bands>",
                 node.to_s(:level => 1))
  end

  def test_to_s_encoding
    # Test encodings
    node = @doc.root

    # UTF8:
    # ö - c3 b6 in hex, \303\266 in octal
    # ü - c3 bc in hex, \303\274 in octal
    assert_equal("<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 node.to_s(:encoding => XML::Input::UTF_8))

    # ISO_8859_1:
    # ö - f6 in hex, \366 in octal
    # ü - fc in hex, \374 in octal
    assert_equal("<bands genre=\"metal\">\n  <m\366tley_cr\374e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\366tley_cr\374e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>",
                 node.to_s(:encoding => XML::Input::ISO_8859_1))


    # Invalid encoding
    error = assert_raise(ArgumentError) do
      node.to_s(:encoding => -9999)
    end
    assert_equal('Unknown encoding.', error.to_s)
  end

  # --- Debug ---
  def test_debug
    assert(@doc.root.debug)
  end
end