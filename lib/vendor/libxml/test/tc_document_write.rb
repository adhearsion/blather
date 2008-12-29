require 'xml'
require 'tmpdir'
require 'test/unit'

class TestDocumentWrite < Test::Unit::TestCase
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

  # ---  to_s tests  ---
  def test_to_s_default
    # Default to_s has indentation
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                 @doc.to_s)
  end

  def test_to_s_no_global_indentation
    # No indentation due to global setting
    XML.indent_tree_output = false
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n<m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n<iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                 @doc.to_s)
  ensure
    XML.indent_tree_output = true
  end

  def test_to_s_no_indentation
    # No indentation due to local setting
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\"><m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e><iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden></bands>\n",
                 @doc.to_s(:indent => false))
  end

  def test_to_s_encoding
    # Test encodings

    # UTF8:
    # ö - c3 b6 in hex, \303\266 in octal
    # ü - c3 bc in hex, \303\274 in octal
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                 @doc.to_s(:encoding => XML::Input::UTF_8))

    # ISO_8859_1:
    # ö - f6 in hex, \366 in octal
    # ü - fc in hex, \374 in octal
    assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\">\n  <m\366tley_cr\374e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\366tley_cr\374e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                 @doc.to_s(:encoding => XML::Input::ISO_8859_1))


    # Invalid encoding
    error = assert_raise(ArgumentError) do
      @doc.to_s(:encoding => -9999)
    end
    assert_equal('Unknown encoding.', error.to_s)
  end

  # --- save tests -----
  def test_save_utf8
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_utf8.xml")

    bytes = @doc.save(temp_filename)
    assert_equal(271, bytes)

    contents = File.read(temp_filename)
    assert_equal("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<bands genre=\"metal\">\n  <m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
               contents)
  ensure
    File.delete(temp_filename)
  end

  def test_save_utf8_no_indents
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_utf8_no_indents.xml")

    bytes = @doc.save(temp_filename, :indent => false)
    assert_equal(264, bytes)

    contents = File.read(temp_filename)
    assert_equal("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<bands genre=\"metal\"><m\303\266tley_cr\303\274e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\303\266tley_cr\303\274e><iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden></bands>\n",
               contents)
  ensure
    File.delete(temp_filename)
  end

  def test_save_iso_8859_1
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_iso_8859_1.xml")
    bytes = @doc.save(temp_filename, :encoding => XML::Input::ISO_8859_1)
    assert_equal(272, bytes)

    contents = File.read(temp_filename)
    assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\">\n  <m\366tley_cr\374e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\366tley_cr\374e>\n  <iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden>\n</bands>\n",
                 contents)
  ensure
    File.delete(temp_filename)
  end

  def test_save_iso_8859_1_no_indent
    temp_filename = File.join(Dir.tmpdir, "tc_document_write_test_save_iso_8859_1_no_indent.xml")
    bytes = @doc.save(temp_filename, :indent => false, :encoding => XML::Input::ISO_8859_1)
    assert_equal(265, bytes)

    contents = File.read(temp_filename)
    assert_equal("<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<bands genre=\"metal\"><m\366tley_cr\374e country=\"us\">An American heavy metal band formed in Los Angeles, California in 1981.</m\366tley_cr\374e><iron_maiden country=\"uk\">British heavy metal band formed in 1975.</iron_maiden></bands>\n",
                 contents)
  ensure
    File.delete(temp_filename)
  end

  # --- Debug ---
  def test_debug
    assert(@doc.debug)
  end
end