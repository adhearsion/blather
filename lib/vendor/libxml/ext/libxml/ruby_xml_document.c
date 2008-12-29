/* $Id: ruby_xml_document.c 688 2008-12-13 01:23:01Z cfis $ */

/*
 * Document-class: LibXML::XML::Document
 *
 * The XML::Document class provides a tree based API for working
 * with xml documents.  You may directly create a document and
 * manipulate it, or create a document from a data source by
 * using an XML::Parser object.
 *
 * To create a document from scratch:
 *
 *  doc = XML::Document.new()
 *  doc.root = XML::Node.new('root_node')
 *  doc.root << XML::Node.new('elem1')
 *  doc.save('output.xml', format)
 *
 * To read a document from a file:
 *
 *   doc = XML::Document.file('my_file')
 *
 * To use a parser to read a document:
 *
 *   parser = XML::Parser.new
 *   parser.file = 'my_file'
 *   doc = parser.parse
 *
 * To write a file:
 *
 *
 *  doc = XML::Document.new()
 *  doc.root = XML::Node.new('root_node')
 *  root = doc.root
 *
 *  root << elem1 = XML::Node.new('elem1')
 *  elem1['attr1'] = 'val1'
 *  elem1['attr2'] = 'val2'
 *
 *  root << elem2 = XML::Node.new('elem2')
 *  elem2['attr1'] = 'val1'
 *  elem2['attr2'] = 'val2'
 *
 *  root << elem3 = XML::Node.new('elem3')
 *  elem3 << elem4 = XML::Node.new('elem4')
 *  elem3 << elem5 = XML::Node.new('elem5')
 *
 *  elem5 << elem6 = XML::Node.new('elem6')
 *  elem6 << 'Content for element 6'
 *
 *  elem3['attr'] = 'baz'
 *
 *  format = true
 *  doc.save('output.xml', format)
 */

#include <stdarg.h>
#include <st.h>
#include "ruby_libxml.h"
#include "ruby_xml_document.h"

VALUE cXMLDocument;

static void LibXML_validity_warning(void * ctxt, const char * msg, va_list ap)
{
  if (rb_block_given_p())
  {
    char buff[1024];
    snprintf(buff, 1024, msg, ap);
    rb_yield(rb_ary_new3(2, rb_str_new2(buff), Qfalse));
  }
  else
  {
    fprintf(stderr, "warning -- found validity error: ");
    fprintf(stderr, msg, ap);
  }
}

void rxml_document_free(xmlDocPtr xdoc)
{
  xdoc->_private = NULL;
  xmlFreeDoc(xdoc);
}

void rxml_document_mark(xmlDocPtr xdoc)
{
  rb_gc_mark(LIBXML_STATE);
}

VALUE rxml_document_wrap(xmlDocPtr xdoc)
{
  VALUE result;

  // This node is already wrapped
  if (xdoc->_private != NULL)
  {
    result = (VALUE) xdoc->_private;
  }
  else
  {
    result = Data_Wrap_Struct(cXMLDocument, rxml_document_mark,
        rxml_document_free, xdoc);
    xdoc->_private = (void*) result;
  }

  return result;
}

/*
 * call-seq:
 *    XML::Document.alloc(xml_version = 1.0) -> document
 *
 * Alocates a new XML::Document, optionally specifying the
 * XML version.
 */
static VALUE rxml_document_alloc(VALUE klass)
{
  return Data_Wrap_Struct(klass, rxml_document_mark, rxml_document_free, NULL);
}

/*
 * call-seq:
 *    XML::Document.initialize(xml_version = 1.0) -> document
 *
 * Initializes a new XML::Document, optionally specifying the
 * XML version.
 */
static VALUE rxml_document_initialize(int argc, VALUE *argv, VALUE self)
{
  xmlDocPtr xdoc;
  VALUE xmlver;

  switch (argc)
  {
  case 0:
    xmlver = rb_str_new2("1.0");
    break;
  case 1:
    rb_scan_args(argc, argv, "01", &xmlver);
    break;
  default:
    rb_raise(rb_eArgError, "wrong number of arguments (need 0 or 1)");
  }

  Check_Type(xmlver, T_STRING);
  xdoc = xmlNewDoc((xmlChar*) StringValuePtr(xmlver));
  xdoc->_private = (void*) self;
  DATA_PTR( self) = xdoc;

  return self;
}

/*
 * call-seq:
 *    document.compression -> num
 *
 * Obtain this document's compression mode identifier.
 */
static VALUE rxml_document_compression_get(VALUE self)
{
#ifdef HAVE_ZLIB_H
  xmlDocPtr xdoc;

  int compmode;
  Data_Get_Struct(self, xmlDoc, xdoc);

  compmode = xmlGetDocCompressMode(xdoc);
  if (compmode == -1)
  return(Qnil);
  else
  return(INT2NUM(compmode));
#else
  rb_warn("libxml not compiled with zlib support");
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    document.compression = num
 *
 * Set this document's compression mode.
 */
static VALUE rxml_document_compression_set(VALUE self, VALUE num)
{
#ifdef HAVE_ZLIB_H
  xmlDocPtr xdoc;

  int compmode;
  Check_Type(num, T_FIXNUM);
  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc == NULL)
  {
    return(Qnil);
  }
  else
  {
    xmlSetDocCompressMode(xdoc, NUM2INT(num));

    compmode = xmlGetDocCompressMode(xdoc);
    if (compmode == -1)
    return(Qnil);
    else
    return(INT2NUM(compmode));
  }
#else
  rb_warn("libxml compiled without zlib support");
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    document.compression? -> (true|false)
 *
 * Determine whether this document is compressed.
 */
static VALUE rxml_document_compression_q(VALUE self)
{
#ifdef HAVE_ZLIB_H
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->compression != -1)
  return(Qtrue);
  else
  return(Qfalse);
#else
  rb_warn("libxml compiled without zlib support");
  return (Qfalse);
#endif
}

/*
 * call-seq:
 *    document.child -> node
 *
 * Get this document's child node.
 */
static VALUE rxml_document_child_get(VALUE self)
{
  xmlDocPtr xdoc;
  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->children == NULL)
    return (Qnil);

  return rxml_node_wrap(cXMLNode, xdoc->children);
}

/*
 * call-seq:
 *    document.child? -> (true|false)
 *
 * Determine whether this document has a child node.
 */
static VALUE rxml_document_child_q(VALUE self)
{
  xmlDocPtr xdoc;
  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->children == NULL)
    return (Qfalse);
  else
    return (Qtrue);
}


/*
 * call-seq:
 *    node.debug -> true|false
 *
 * Print libxml debugging information to stdout.
 * Requires that libxml was compiled with debugging enabled.
*/
static VALUE rxml_document_debug(VALUE self)
{
#ifdef LIBXML_DEBUG_ENABLED
  xmlDocPtr xdoc;
  Data_Get_Struct(self, xmlDoc, xdoc);
  xmlDebugDumpDocument(NULL, xdoc);
  return Qtrue;
#else
  rb_warn("libxml was compiled without debugging support.")
  return Qfalse;
#endif
}

/*
 * call-seq:
 *    document.encoding -> "encoding"
 *
 * Obtain the encoding specified by this document.
 */
static VALUE rxml_document_encoding_get(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);
  if (xdoc->encoding == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) xdoc->encoding));
}

/*
 * call-seq:
 *    document.encoding = "encoding"
 *
 * Set the encoding for this document.
 */
static VALUE rxml_document_encoding_set(VALUE self, VALUE encoding)
{
  xmlDocPtr xdoc;

  Check_Type(encoding, T_STRING);
  Data_Get_Struct(self, xmlDoc, xdoc);
  xdoc->encoding = xmlStrdup((xmlChar *)StringValuePtr(encoding));
  return (rxml_document_encoding_get(self));
}

/*
 * call-seq:
 *    document.last -> node
 *
 * Obtain the last node.
 */
static VALUE rxml_document_last_get(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->last == NULL)
    return (Qnil);

  return rxml_node_wrap(cXMLNode, xdoc->last);
}

/*
 * call-seq:
 *    document.last? -> (true|false)
 *
 * Determine whether there is a last node.
 */
static VALUE rxml_document_last_q(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->last == NULL)
    return (Qfalse);
  else
    return (Qtrue);
}

/*
 * call-seq:
 *    document.next -> node
 *
 * Obtain the next node.
 */
static VALUE rxml_document_next_get(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->next == NULL)
    return (Qnil);

  return rxml_node_wrap(cXMLNode, xdoc->next);
}

/*
 * call-seq:
 *    document.next? -> (true|false)
 *
 * Determine whether there is a next node.
 */
static VALUE rxml_document_next_q(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->next == NULL)
    return (Qfalse);
  else
    return (Qtrue);
}

/*
 * call-seq:
 *    document.parent -> node
 *
 * Obtain the parent node.
 */
static VALUE rxml_document_parent_get(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->parent == NULL)
    return (Qnil);

  return rxml_node_wrap(cXMLNode, xdoc->parent);
}

/*
 * call-seq:
 *    document.parent? -> (true|false)
 *
 * Determine whether there is a parent node.
 */
static VALUE rxml_document_parent_q(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->parent == NULL)
    return (Qfalse);
  else
    return (Qtrue);
}

/*
 * call-seq:
 *    document.prev -> node
 *
 * Obtain the previous node.
 */
static VALUE rxml_document_prev_get(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->prev == NULL)
    return (Qnil);

  return rxml_node_wrap(cXMLNode, xdoc->prev);
}

/*
 * call-seq:
 *    document.prev? -> (true|false)
 *
 * Determine whether there is a previous node.
 */
static VALUE rxml_document_prev_q(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);

  if (xdoc->prev == NULL)
    return (Qfalse);
  else
    return (Qtrue);
}

/*
 * call-seq:
 *    document.root -> node
 *
 * Obtain the root node.
 */
static VALUE rxml_document_root_get(VALUE self)
{
  xmlDocPtr xdoc;

  xmlNodePtr root;

  Data_Get_Struct(self, xmlDoc, xdoc);
  root = xmlDocGetRootElement(xdoc);

  if (root == NULL)
    return (Qnil);

  return rxml_node_wrap(cXMLNode, root);
}

/*
 * call-seq:
 *    document.root = node
 *
 * Set the root node.
 */
static VALUE rxml_document_root_set(VALUE self, VALUE node)
{
  xmlDocPtr xdoc;
  xmlNodePtr xroot, xnode;

  if (rb_obj_is_kind_of(node, cXMLNode) == Qfalse)
    rb_raise(rb_eTypeError, "must pass an XML::Node type object");

  Data_Get_Struct(self, xmlDoc, xdoc);
  Data_Get_Struct(node, xmlNode, xnode);
  xroot = xmlDocSetRootElement(xdoc, xnode);
  if (xroot == NULL)
    return (Qnil);

  return rxml_node_wrap(cXMLNode, xroot);
}

/*
 * call-seq:
 *    document.save(filename) -> int
 *    document.save(filename, :indent => true, :encoding => 'UTF-8') -> int
 *
 * Saves a document to a file.  You may provide an optional hash table
 * to control how the string is generated.  Valid options are:
 * 
 * :indent - Specifies if the string should be indented.  The default value
 * is true.  Note that indentation is only added if both :indent is
 * true and XML.indent_tree_output is true.  If :indent is set to false,
 * then both indentation and line feeds are removed from the result.
 *
 * :encoding - Specifies the output encoding of the string.  It
 * defaults to the original encoding of the document (see
 * #encoding.  To override the orginal encoding, use one of the
 * XML::Input encoding constants. */
static VALUE rxml_document_save(int argc, VALUE *argv, VALUE self)
{ 
  VALUE options = Qnil;
  VALUE filename = Qnil;
  xmlDocPtr xdoc;
  int indent = 1;
  const char *xfilename;
  const char *encoding;
  int length;

  rb_scan_args(argc, argv, "11", &filename, &options);

  Check_Type(filename, T_STRING);
  xfilename = StringValuePtr(filename);

  Data_Get_Struct(self, xmlDoc, xdoc);
  encoding = xdoc->encoding;

  if (!NIL_P(options))
  {
    VALUE rencoding, rindent;
    Check_Type(options, T_HASH);
    rencoding = rb_hash_aref(options, ID2SYM(rb_intern("encoding")));
    rindent = rb_hash_aref(options, ID2SYM(rb_intern("indent")));

    if (rindent == Qfalse)
      indent = 0;

    if (rencoding != Qnil)
      encoding = RSTRING_PTR(rxml_input_encoding_to_s(cXMLInput, rencoding));
  }

  length = xmlSaveFormatFileEnc(xfilename, xdoc, encoding, indent);

  if (length == -1)
    rxml_raise(&xmlLastError);
  
  return (INT2NUM(length));
}

/*
 * call-seq:
 *    document.standalone? -> (true|false)
 *
 * Determine whether this is a standalone document.
 */
static VALUE rxml_document_standalone_q(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);
  if (xdoc->standalone)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    document.to_s -> "string"
 *    document.to_s(:indent => true, :encoding => 'UTF-8') -> "string"
 *
 * Converts a document, and all of its children, to a string representation.
 * You may provide an optional hash table to control how the string is 
 * generated.  Valid options are:
 * 
 * :indent - Specifies if the string should be indented.  The default value
 * is true.  Note that indentation is only added if both :indent is
 * true and XML.indent_tree_output is true.  If :indent is set to false,
 * then both indentation and line feeds are removed from the result.
 *
 * :encoding - Specifies the output encoding of the string.  It
 * defaults to XML::Input::UTF8.  To change it, use one of the
 * XML::Input encoding constants. */
static VALUE rxml_document_to_s(int argc, VALUE *argv, VALUE self)
{ 
  VALUE result;
  VALUE options = Qnil;
  xmlDocPtr xdoc;
  int indent = 1;
  const char *encoding = "UTF-8";
  xmlChar *buffer; 
  int length;

  rb_scan_args(argc, argv, "01", &options);

  if (!NIL_P(options))
  {
    VALUE rencoding, rindent;
    Check_Type(options, T_HASH);
    rencoding = rb_hash_aref(options, ID2SYM(rb_intern("encoding")));
    rindent = rb_hash_aref(options, ID2SYM(rb_intern("indent")));

    if (rindent == Qfalse)
      indent = 0;

    if (rencoding != Qnil)
      encoding = RSTRING_PTR(rxml_input_encoding_to_s(cXMLInput, rencoding));
  }

  Data_Get_Struct(self, xmlDoc, xdoc);
  xmlDocDumpFormatMemoryEnc(xdoc, &buffer, &length, encoding, indent);

  result = rb_str_new((const char*) buffer, length);
  xmlFree(buffer);
  return result;
}

/*
 * call-seq:
 *    document.url -> "url"
 *
 * Obtain this document's source URL, if any.
 */
static VALUE rxml_document_url_get(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);
  if (xdoc->URL == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) xdoc->URL));
}

/*
 * call-seq:
 *    document.version -> "version"
 *
 * Obtain the XML version specified by this document.
 */
static VALUE rxml_document_version_get(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);
  if (xdoc->version == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) xdoc->version));
}

/*
 * call-seq:
 *    document.xinclude -> num
 *
 * Process xinclude directives in this document.
 */
static VALUE rxml_document_xinclude(VALUE self)
{
#ifdef LIBXML_XINCLUDE_ENABLED
  xmlDocPtr xdoc;

  int ret;

  Data_Get_Struct(self, xmlDoc, xdoc);
  ret = xmlXIncludeProcess(xdoc);
  if (ret >= 0)
  {
    return(INT2NUM(ret));
  }
  else
  {
    rxml_raise(&xmlLastError);
    return Qnil;
  }
#else
  rb_warn(
      "libxml was compiled without XInclude support.  Please recompile libxml and ruby-libxml");
  return (Qfalse);
#endif
}

void LibXML_validity_error(void * ctxt, const char * msg, va_list ap)
{
  if (rb_block_given_p())
  {
    char buff[1024];
    snprintf(buff, 1024, msg, ap);
    rb_yield(rb_ary_new3(2, rb_str_new2(buff), Qtrue));
  }
  else
  {
    fprintf(stderr, "error -- found validity error: ");
    fprintf(stderr, msg, ap);
  }
}

/*
 * call-seq:
 *    document.order_elements! 
 * 
 * Call this routine to speed up XPath computation on static documents.
 * This stamps all the element nodes with the document order. 
 */
static VALUE rxml_document_order_elements(VALUE self)
{
  xmlDocPtr xdoc;

  Data_Get_Struct(self, xmlDoc, xdoc);
  return LONG2FIX(xmlXPathOrderDocElems(xdoc));
}

/*
 * call-seq:
 *    document.validate_schema(schema) -> (true|false)
 *
 * Validate this document against the specified XML::Schema.
 *
 * If a block is provided it is used as an error handler for validaten errors.
 * The block is called with two argument, the message and a flag indication
 * if the message is an error (true) or a warning (false).
 */
static VALUE rxml_document_validate_schema(VALUE self, VALUE schema)
{
  xmlSchemaValidCtxtPtr vptr;
  xmlDocPtr xdoc;
  xmlSchemaPtr xschema;
  int is_invalid;

  Data_Get_Struct(self, xmlDoc, xdoc);
  Data_Get_Struct(schema, xmlSchema, xschema);

  vptr = xmlSchemaNewValidCtxt(xschema);

  xmlSchemaSetValidErrors(vptr,
      (xmlSchemaValidityErrorFunc) LibXML_validity_error,
      (xmlSchemaValidityWarningFunc) LibXML_validity_warning, NULL);

  is_invalid = xmlSchemaValidateDoc(vptr, xdoc);
  xmlSchemaFreeValidCtxt(vptr);
  if (is_invalid)
  {
    rxml_raise(&xmlLastError);
    return Qfalse;
  }
  else
  {
    return Qtrue;
  }
}

/*
 * call-seq:
 *    document.validate_schema(relaxng) -> (true|false)
 *
 * Validate this document against the specified XML::RelaxNG.
 *
 * If a block is provided it is used as an error handler for validaten errors.
 * The block is called with two argument, the message and a flag indication
 * if the message is an error (true) or a warning (false).
 */
static VALUE rxml_document_validate_relaxng(VALUE self, VALUE relaxng)
{
  xmlRelaxNGValidCtxtPtr vptr;
  xmlDocPtr xdoc;
  xmlRelaxNGPtr xrelaxng;
  int is_invalid;

  Data_Get_Struct(self, xmlDoc, xdoc);
  Data_Get_Struct(relaxng, xmlRelaxNG, xrelaxng);

  vptr = xmlRelaxNGNewValidCtxt(xrelaxng);

  xmlRelaxNGSetValidErrors(vptr,
      (xmlRelaxNGValidityErrorFunc) LibXML_validity_error,
      (xmlRelaxNGValidityWarningFunc) LibXML_validity_warning, NULL);

  is_invalid = xmlRelaxNGValidateDoc(vptr, xdoc);
  xmlRelaxNGFreeValidCtxt(vptr);
  if (is_invalid)
  {
    rxml_raise(&xmlLastError);
    return Qfalse;
  }
  else
  {
    return Qtrue;
  }
}

/*
 * call-seq:
 *    document.validate(dtd) -> (true|false)
 *
 * Validate this document against the specified XML::DTD.
 */
static VALUE rxml_document_validate_dtd(VALUE self, VALUE dtd)
{
  VALUE error = Qnil;
  xmlValidCtxt ctxt;
  xmlDocPtr xdoc;
  xmlDtdPtr xdtd;

  Data_Get_Struct(self, xmlDoc, xdoc);
  Data_Get_Struct(dtd, xmlDtd, xdtd);

  ctxt.userData = &error;
  ctxt.error = (xmlValidityErrorFunc) LibXML_validity_error;
  ctxt.warning = (xmlValidityWarningFunc) LibXML_validity_warning;

  ctxt.nodeNr = 0;
  ctxt.nodeTab = NULL;
  ctxt.vstateNr = 0;
  ctxt.vstateTab = NULL;

  if (xmlValidateDtd(&ctxt, xdoc, xdtd))
  {
    return (Qtrue);
  }
  else
  {
    rxml_raise(&xmlLastError);
    return Qfalse;
  }
}

/*
 * call-seq:
 *    document.reader -> reader
 *
 * Create a XML::Reader from the document. This is a shortcut to
 * XML::Reader.walker().
 */
static VALUE rxml_document_reader(VALUE self)
{
  return rxml_reader_new_walker(cXMLReader, self);
}

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_xml_document(void)
{
  cXMLDocument = rb_define_class_under(mXML, "Document", rb_cObject);
  rb_define_alloc_func(cXMLDocument, rxml_document_alloc);

  rb_define_method(cXMLDocument, "initialize", rxml_document_initialize, -1);
  rb_define_method(cXMLDocument, "child", rxml_document_child_get, 0);
  rb_define_method(cXMLDocument, "child?", rxml_document_child_q, 0);
  rb_define_method(cXMLDocument, "compression", rxml_document_compression_get, 0);
  rb_define_method(cXMLDocument, "compression=", rxml_document_compression_set, 1);
  rb_define_method(cXMLDocument, "compression?", rxml_document_compression_q, 0);
  rb_define_method(cXMLDocument, "debug", rxml_document_debug, 0);
  rb_define_method(cXMLDocument, "encoding", rxml_document_encoding_get, 0);
  rb_define_method(cXMLDocument, "encoding=", rxml_document_encoding_set, 1);
  rb_define_method(cXMLDocument, "last", rxml_document_last_get, 0);
  rb_define_method(cXMLDocument, "last?", rxml_document_last_q, 0);
  rb_define_method(cXMLDocument, "next", rxml_document_next_get, 0);
  rb_define_method(cXMLDocument, "next?", rxml_document_next_q, 0);
  rb_define_method(cXMLDocument, "order_elements!", rxml_document_order_elements, 0);
  rb_define_method(cXMLDocument, "parent", rxml_document_parent_get, 0);
  rb_define_method(cXMLDocument, "parent?", rxml_document_parent_q, 0);
  rb_define_method(cXMLDocument, "prev", rxml_document_prev_get, 0);
  rb_define_method(cXMLDocument, "prev?", rxml_document_prev_q, 0);
  rb_define_method(cXMLDocument, "root", rxml_document_root_get, 0);
  rb_define_method(cXMLDocument, "root=", rxml_document_root_set, 1);
  rb_define_method(cXMLDocument, "save", rxml_document_save, -1);
  rb_define_method(cXMLDocument, "standalone?", rxml_document_standalone_q, 0);
  rb_define_method(cXMLDocument, "to_s", rxml_document_to_s, -1);
  rb_define_method(cXMLDocument, "url", rxml_document_url_get, 0);
  rb_define_method(cXMLDocument, "version", rxml_document_version_get, 0);
  rb_define_method(cXMLDocument, "xinclude", rxml_document_xinclude, 0);
  rb_define_method(cXMLDocument, "validate", rxml_document_validate_dtd, 1);
  rb_define_method(cXMLDocument, "validate_schema", rxml_document_validate_schema, 1);
  rb_define_method(cXMLDocument, "validate_relaxng", rxml_document_validate_relaxng, 1);
  rb_define_method(cXMLDocument, "reader", rxml_document_reader, 0);
}
