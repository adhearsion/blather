#include "ruby_libxml.h"
#include "ruby_xml_sax_push_parser.h"

VALUE cXMLSaxPushParser;

ID CALLBACK_ATTR;

static void free_parser(xmlParserCtxtPtr ctxt)
{
  xmlFreeParserCtxt(ctxt);
}

static VALUE rxml_sax_push_parser_initialize(VALUE self, VALUE handler)
{
  rb_ivar_set(self, CALLBACK_ATTR, handler);

  xmlParserCtxtPtr ctxt;
  VALUE parser;
  
  ctxt = xmlCreatePushParserCtxt(&rxml_sax_handler, (void *)handler, NULL, 0, NULL);
  
  if (!ctxt) {
  	rxml_raise(&xmlLastError);
  	return Qnil;
  }
  
  parser = Data_Wrap_Struct(rb_cData, NULL, free_parser, ctxt);
  rb_iv_set(self, "@parser", parser); 

  return self;
}

static VALUE rxml_sax_push_parser_close(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  
  Data_Get_Struct(rb_iv_get(self, "@parser"), xmlParserCtxt, ctxt);
  
  if (xmlParseChunk(ctxt,	"", 0, 1)) {
    rxml_raise(&xmlLastError);
    return Qfalse;
  }
  else {
    return Qtrue;
  }
}

static VALUE rxml_sax_push_parser_receive(VALUE self, VALUE chunk)
{
  xmlParserCtxtPtr ctxt;

  const char *data = StringValuePtr(chunk);
  int length = RSTRING_LEN(chunk);

  Data_Get_Struct(rb_iv_get(self, "@parser"), xmlParserCtxt, ctxt);

  // Chunk through in 4KB chunks so as not to overwhelm the buffers
  int i;
  int chunkSize = length < 4096 ? length : 4096;
  for (i = 0; i < length; i += chunkSize) {
    xmlParseChunk(ctxt, data+i, chunkSize, 0);
  }
  if ((i -= length) > 0)
    xmlParseChunk(ctxt, data+(length-i), i, 0);

  return (VALUE)ctxt->myDoc;
}

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_xml_sax_push_parser(void)
{
  /* SaxPushParser */
  cXMLSaxPushParser = rb_define_class_under(mXML, "SaxPushParser", rb_cObject);

  CALLBACK_ATTR = rb_intern("@callbacks");
  rb_define_attr(cXMLSaxPushParser, "callbacks", 1, 0);

  /* Instance Methods */
  rb_define_method(cXMLSaxPushParser, "initialize", rxml_sax_push_parser_initialize, 1);
  rb_define_method(cXMLSaxPushParser, "receive", rxml_sax_push_parser_receive, 1);
  rb_define_method(cXMLSaxPushParser, "close", rxml_sax_push_parser_close, 0);
}
