/* $Id: ruby_xml_html_parser.c 665 2008-12-06 07:52:49Z cfis $ */

/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"

VALUE cXMLHTMLParser;
static ID INPUT_ATTR;

/*
 * Document-class: LibXML::XML::HTMLParser
 *
 * The HTML parser implements an HTML 4.0 non-verifying parser with an API
 * compatible with the XML::Parser.  In contrast with the XML::Parser,
 * it can parse "real world" HTML, even if it severely broken from a
 * specification point of view. */

/*
 * call-seq:
 *    XML::HTMLParser.initialize -> parser
 *
 * Initializes a new parser instance with no pre-determined source.
 */
static VALUE rxml_html_parser_initialize(VALUE self)
{
  VALUE input = rb_class_new_instance(0, NULL, cXMLInput);
  rb_iv_set(self, "@input", input);
  return self;
}

static htmlDocPtr rxml_html_parser_read_file(VALUE input)
{
  VALUE file = rb_ivar_get(input, FILE_ATTR);
  VALUE encoding = rb_ivar_get(input, ENCODING_ATTR);
  VALUE encoding_str = rxml_input_encoding_to_s(cXMLInput, encoding);
  char *xencoding_str = (encoding_str == Qnil ? NULL : StringValuePtr(
      encoding_str));
  int options = 0;

  return htmlReadFile(StringValuePtr(file), xencoding_str, options);
}

static htmlDocPtr rxml_html_parser_read_string(VALUE input)
{
  VALUE string = rb_ivar_get(input, STRING_ATTR);
  VALUE base_url = rb_ivar_get(input, BASE_URL_ATTR);
  char *xbase_url = (base_url == Qnil ? NULL : StringValuePtr(base_url));
  VALUE encoding = rb_ivar_get(input, ENCODING_ATTR);
  VALUE encoding_str = rxml_input_encoding_to_s(cXMLInput, encoding);
  char *xencoding_str = (encoding_str == Qnil ? NULL : StringValuePtr(
      encoding_str));
  int options = 0;

  return htmlReadMemory(StringValuePtr(string), RSTRING_LEN(string),
                        xbase_url, xencoding_str, options);
}

static htmlDocPtr rxml_html_parser_read_io(VALUE input)
{
  VALUE io = rb_ivar_get(input, IO_ATTR);
  VALUE base_url = rb_ivar_get(input, BASE_URL_ATTR);
  char *xbase_url = (base_url == Qnil ? NULL : StringValuePtr(base_url));
  VALUE encoding = rb_ivar_get(input, ENCODING_ATTR);
  VALUE encoding_str = rxml_input_encoding_to_s(cXMLInput, encoding);
  char *xencoding_str = (encoding_str == Qnil ? NULL : StringValuePtr(
      encoding_str));
  int options = 0;

  return htmlReadIO((xmlInputReadCallback) rxml_read_callback, NULL,
      (void *) io, xbase_url, xencoding_str, options);
}

/*
 * call-seq:
 *    parser.parse -> document
 *
 * Parse the input XML and create an XML::Document with
 * it's content. If an error occurs, XML::Parser::ParseError
 * is thrown.
 */
static VALUE rxml_html_parser_parse(VALUE self)
{
  VALUE input = rb_ivar_get(self, INPUT_ATTR);
  htmlDocPtr xdoc;

  if (rb_ivar_get(input, FILE_ATTR) != Qnil)
    xdoc = rxml_html_parser_read_file(input);
  else if (rb_ivar_get(input, STRING_ATTR) != Qnil)
    xdoc = rxml_html_parser_read_string(input);
  else if (rb_ivar_get(input, IO_ATTR) != Qnil)
    xdoc = rxml_html_parser_read_io(input);
  else
    rb_raise(rb_eArgError, "You must specify a parser data source");

  if (!xdoc)
    rxml_raise(&xmlLastError);

  return rxml_document_wrap(xdoc);
}

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_html_parser(void)
{
  INPUT_ATTR = rb_intern("@input");

  cXMLHTMLParser = rb_define_class_under(mXML, "HTMLParser", rb_cObject);

  /* Atributes */
  rb_define_attr(cXMLHTMLParser, "input", 1, 0);

  /* Instance methods */
  rb_define_method(cXMLHTMLParser, "initialize", rxml_html_parser_initialize, 0);
  rb_define_method(cXMLHTMLParser, "parse", rxml_html_parser_parse, 0);
}
