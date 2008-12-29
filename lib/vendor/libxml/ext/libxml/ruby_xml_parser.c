/* $Id: ruby_xml_parser.c 650 2008-11-30 03:40:22Z cfis $ */

/* Please see the LICENSE file for copyright and distribution information */

#include <stdarg.h>
#include "ruby_libxml.h"

VALUE cXMLParser;
static ID INPUT_ATTR;
static ID CONTEXT_ATTR;

/*
 * Document-class: LibXML::XML::Parser
 *
 * The XML::Parser provides a tree based API for processing
 * xml documents, in contract to XML::Reader's stream
 * based api and XML::SaxParser callback based API.
 *
 * As a result, parsing a document creates an in-memory document object
 * that consist of any number of XML::Node instances.  This is simple
 * and powerful model, but has the major limitation that the size of
 * the document that can be processed is limited by the amount of
 * memory available.  In such cases, it is better to use the XML::Reader.
 *
 * Using the parser is simple:
 *
 *   parser = XML::Parser.new
 *   parser.file = 'my_file'
 *   doc = parser.parse
 *
 * You can also parse strings (see XML::Parser.string) and io objects (see
 * XML::Parser.io).
 */

/*
 * call-seq:
 *    parser.initialize -> parser
 *
 * Initiliazes instance of parser.
 */
static VALUE rxml_parser_initialize(VALUE self)
{
  VALUE input = rb_class_new_instance(0, NULL, cXMLInput);
  rb_iv_set(self, "@input", input);
  rb_iv_set(self, "@context", Qnil);
  return self;
}

static xmlParserCtxtPtr rxml_parser_filename_ctxt(VALUE input)
{
  xmlParserCtxtPtr ctxt;
  int retry_count = 0;
  VALUE filename = rb_ivar_get(input, FILE_ATTR);

  retry: ctxt = xmlCreateFileParserCtxt(StringValuePtr(filename));
  if (ctxt == NULL)
  {
    if ((errno == EMFILE || errno == ENFILE) && retry_count == 0)
    {
      retry_count++;
      rb_gc();
      goto retry;
    }
    else
    {
      rb_raise(rb_eIOError, StringValuePtr(filename));
    }
  }

  return ctxt;
}

static xmlParserCtxtPtr rxml_parser_str_ctxt(VALUE input)
{
  VALUE str = rb_ivar_get(input, STRING_ATTR);
  return xmlCreateMemoryParserCtxt(StringValuePtr(str), RSTRING_LEN(str));
}

static xmlParserCtxtPtr rxml_parser_io_ctxt(VALUE input)
{
  VALUE io = rb_ivar_get(input, IO_ATTR);
  VALUE encoding = rb_ivar_get(input, ENCODING_ATTR);
  xmlCharEncoding xmlEncoding = NUM2INT(encoding);

  return xmlCreateIOParserCtxt(NULL, NULL,
      (xmlInputReadCallback) rxml_read_callback, NULL, (void *) io, xmlEncoding);
}

/*
 * call-seq:
 *    parser.parse -> document
 *
 * Parse the input XML and create an XML::Document with
 * it's content. If an error occurs, XML::Parser::ParseError
 * is thrown.
 */
static VALUE rxml_parser_parse(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  VALUE context;
  VALUE input = rb_ivar_get(self, INPUT_ATTR);

  context = rb_ivar_get(self, CONTEXT_ATTR);
  if (context != Qnil)
    rb_raise(rb_eRuntimeError, "You cannot parse a data source twice");

  if (rb_ivar_get(input, FILE_ATTR) != Qnil)
    ctxt = rxml_parser_filename_ctxt(input);
  else if (rb_ivar_get(input, STRING_ATTR) != Qnil)
    ctxt = rxml_parser_str_ctxt(input);
  /*else if (rb_ivar_get(input, DOCUMENT_ATTR) != Qnil)
   ctxt = rxml_parser_parse_document(input);*/
  else if (rb_ivar_get(input, IO_ATTR) != Qnil)
    ctxt = rxml_parser_io_ctxt(input);
  else
    rb_raise(rb_eArgError, "You must specify a parser data source");

  if (!ctxt)
    rxml_raise(&xmlLastError);

  context = rxml_parser_context_wrap(ctxt);
  rb_ivar_set(self, CONTEXT_ATTR, context);

  if (xmlParseDocument(ctxt) == -1 || !ctxt->wellFormed)
  {
    xmlFreeDoc(ctxt->myDoc);
    rxml_raise(&ctxt->lastError);
  }

  return rxml_document_wrap(ctxt->myDoc);
}

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_parser(void)
{
  cXMLParser = rb_define_class_under(mXML, "Parser", rb_cObject);

  /* Atributes */
  INPUT_ATTR = rb_intern("@input");
  CONTEXT_ATTR = rb_intern("@context");
  rb_define_attr(cXMLParser, "input", 1, 0);
  rb_define_attr(cXMLParser, "context", 1, 0);

  /* Instance Methods */
  rb_define_method(cXMLParser, "initialize", rxml_parser_initialize, 0);
  rb_define_method(cXMLParser, "parse", rxml_parser_parse, 0);
}
