/*
 * Most of this was ripped from libxml-ruby's SAX handler
 */

#include <libxml/parser.h>
#include <libxml/tree.h>
#include <ruby.h>

xmlSAXHandler saxHandler;

static VALUE push_parser_initialize (
  VALUE self,
  VALUE handler)
{
  xmlParserCtxtPtr ctxt;
  ctxt = xmlCreatePushParserCtxt(&saxHandler, (void *)handler, NULL, 0, NULL);
  
  if (!ctxt) {
    rxml_raise(&xmlLastError);
    return Qnil;
  }

  ctxt->sax2 = 1;
  rb_iv_set(self, "@__libxml_parser", Data_Wrap_Struct(rb_cData, NULL, xmlFreeParserCtxt, ctxt));

  return self;
}

static VALUE push_parser_close (
  VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(rb_iv_get(self, "@__libxml_parser"), xmlParserCtxt, ctxt);
  
  if (xmlParseChunk(ctxt, "", 0, 1)) {
    rxml_raise(&xmlLastError);
    return Qfalse;
  }
  else {
    return Qtrue;
  }
}

static VALUE push_parser_receive (
  VALUE self,
  VALUE chunk)
{
  const char *data = StringValuePtr(chunk);
  int length = RSTRING_LEN(chunk);

  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(rb_iv_get(self, "@__libxml_parser"), xmlParserCtxt, ctxt);

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

/*********
 CALLBACKS
**********/
static void push_parser_start_document_callback (
  void *ctxt)
{
  VALUE handler = (VALUE) ctxt;
  if (handler != Qnil)
    rb_funcall (handler, rb_intern("on_start_document"), 0);
}

static void push_parser_end_document_callback (
  void *ctxt)
{
  VALUE handler = (VALUE) ctxt;
  if (handler != Qnil)
    rb_funcall (handler, rb_intern("on_end_document"), 0);
}

static void push_parser_start_element_ns_callback (
  void * ctxt,
  const xmlChar * xlocalname, 
  const xmlChar * xprefix, 
  const xmlChar * xURI, 
  int nb_namespaces, 
  const xmlChar ** xnamespaces, 
  int nb_attributes, 
  int nb_defaulted, 
  const xmlChar ** xattributes)
{
  VALUE handler = (VALUE) ctxt;
  if (handler == Qnil)
    return;

  VALUE attributes = rb_hash_new();
  VALUE namespaces = rb_hash_new();

  if (xattributes)
  {
    /* Each attribute is an array of [localname, prefix, URI, value, end] */
    int i;
    for (i = 0;i < nb_attributes * 5; i+=5) 
    {
      VALUE attrName = rb_str_new2((const char*)xattributes[i+0]);
      VALUE attrValue = rb_str_new((const char*)xattributes[i+3], xattributes[i+4] - xattributes[i+3]);
      rb_hash_aset(attributes, attrName, attrValue);
    }
  }

  if (xnamespaces)
  {
    int i;
    for (i = 0;i < nb_namespaces * 2; i+=2) 
    {
      VALUE nsPrefix = xnamespaces[i+0] ? rb_str_new2((const char*)xnamespaces[i+0]) : Qnil;
      VALUE nsURI = xnamespaces[i+1] ? rb_str_new2((const char*)xnamespaces[i+1]) : Qnil;
      rb_hash_aset(namespaces, nsPrefix, nsURI);
    }
  }

  rb_funcall(handler, rb_intern("on_start_element_ns"), 5, 
             rb_str_new2((const char*)xlocalname),
             attributes,
             xprefix ? rb_str_new2((const char*)xprefix) : Qnil,
             xURI ? rb_str_new2((const char*)xURI) : Qnil,
             namespaces);
}

static void push_parser_end_element_ns_callback (
  void * ctxt,
  const xmlChar * xlocalname, 
  const xmlChar * xprefix, 
  const xmlChar * xURI)
{
  VALUE handler = (VALUE) ctxt;
  if (handler == Qnil)
    return;

  rb_funcall(handler, rb_intern("on_end_element_ns"), 3, 
             rb_str_new2((const char*)xlocalname),
             xprefix ? rb_str_new2((const char*)xprefix) : Qnil,
             xURI ? rb_str_new2((const char*)xURI) : Qnil);
}


static void push_parser_characters_callback (
  void *ctxt,
  const char *chars,
  int len)
{
  VALUE handler = (VALUE) ctxt;
  if (handler != Qnil)
    rb_funcall (handler, rb_intern("on_characters"), 1, rb_str_new(chars, len));
}

static void push_parser_structured_error_callback (
  void *ctxt,
  xmlErrorPtr xerror)
{
  VALUE handler = (VALUE) ctxt;
  if (handler != Qnil)
    rb_funcall (handler, rb_intern("on_error"), 1, rb_str_new2((const char*)xerror->message));
}

xmlSAXHandler saxHandler = {
  0, //internalSubset
  0, //isStandalone
  0, //hasInternalSubset
  0, //hasExternalSubset
  0, //resolveEntity
  0, //getEntity
  0, //entityDecl
  0, //notationDecl
  0, //attributeDecl
  0, //elementDecl
  0, //unparsedEntityDecl
  0, //setDocumentLocator
  (startDocumentSAXFunc) push_parser_start_document_callback,
  (endDocumentSAXFunc) push_parser_end_document_callback,
  0, //startElement
  0, //endElement
  0, //reference
  (charactersSAXFunc) push_parser_characters_callback,
  0, //ignorableWhitespace
  0, //processingInstruction
  0, //comment
  (warningSAXFunc) push_parser_structured_error_callback,
  (errorSAXFunc) push_parser_structured_error_callback,
  (fatalErrorSAXFunc) push_parser_structured_error_callback,
  0, //getParameterEntity
  0, //cdataBlock
  0, //externalSubset
  XML_SAX2_MAGIC,
  0, //_private
  (startElementNsSAX2Func) push_parser_start_element_ns_callback,
  (endElementNsSAX2Func) push_parser_end_element_ns_callback,
  (xmlStructuredErrorFunc) push_parser_structured_error_callback
};

void Init_push_parser()
{
  /* SaxPushParser */
  VALUE mLibXML = rb_define_module("LibXML");
  VALUE mXML = rb_define_module_under(mLibXML, "XML");
  VALUE cXMLSaxPushParser = rb_define_class_under(mXML, "SaxPushParser", rb_cObject);

  /* Instance Methods */
  rb_define_method(cXMLSaxPushParser, "initialize", push_parser_initialize, 1);
  rb_define_method(cXMLSaxPushParser, "receive", push_parser_receive, 1);
  rb_define_method(cXMLSaxPushParser, "close", push_parser_close, 0);
}
