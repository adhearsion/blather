/* $Id: ruby_xml_parser_context.c 659 2008-12-01 17:08:58Z cfis $ */

/* Please see the LICENSE file for copyright and distribution information */

#include "ruby_libxml.h"
#include "ruby_xml_parser_context.h"

VALUE cXMLParserContext;

/*
 * Document-class: LibXML::XML::Parser::Context
 *
 * The XML::Parser::Context class provides in-depth control over how
 * a document is parsed.
 */

static void rxml_parser_context_free(xmlParserCtxtPtr ctxt)
{
  if (ctxt != NULL)
    xmlFreeParserCtxt(ctxt);
}

VALUE rxml_parser_context_wrap(xmlParserCtxtPtr ctxt)
{
  return Data_Wrap_Struct(cXMLParserContext, NULL, rxml_parser_context_free,
      ctxt);
}

/*
 * call-seq:
 *    context.data_directory -> "dir"
 *
 * Obtain the data directory associated with this context.
 */
static VALUE rxml_parser_context_data_directory_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->directory == NULL)
    return (Qnil);
  else
    return (rb_str_new2(ctxt->directory));
}

/*
 * call-seq:
 *    context.depth -> num
 *
 * Obtain the depth of this context.
 */
static VALUE rxml_parser_context_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->depth));
}

/*
 * call-seq:
 *    context.disable_sax? -> (true|false)
 *
 * Determine whether SAX-based processing is disabled
 * in this context.
 */
static VALUE rxml_parser_context_disable_sax_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->disableSAX)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.docbook? -> (true|false)
 *
 * Determine whether this is a docbook context.
 */
static VALUE rxml_parser_context_docbook_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->html == 2) // TODO check this
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.encoding -> "encoding"
 *
 * Obtain the character encoding identifier used in
 * this context.
 */
static VALUE rxml_parser_context_encoding_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->encoding == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) ctxt->encoding));
}

/*
 * call-seq:
 *    context.errno -> num
 *
 * Obtain the last-error number in this context.
 */
static VALUE rxml_parser_context_errno_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->errNo));
}

/*
 * call-seq:
 *    context.html? -> (true|false)
 *
 * Determine whether this is an html context.
 */
static VALUE rxml_parser_context_html_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->html == 1)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.max_num_streams -> num
 *
 * Obtain the limit on the number of IO streams opened in
 * this context.
 */
static VALUE rxml_parser_context_io_max_num_streams_get(VALUE self)
{
  // TODO alias to max_streams and dep this?
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->inputMax));
}

/*
 * call-seq:
 *    context.num_streams -> "dir"
 *
 * Obtain the actual number of IO streams in this
 * context.
 */
static VALUE rxml_parser_context_io_num_streams_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->inputNr));
}

/*
 * call-seq:
 *    context.keep_blanks? -> (true|false)
 *
 * Determine whether parsers in this context retain
 * whitespace.
 */
static VALUE rxml_parser_context_keep_blanks_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->keepBlanks)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.name_depth -> num
 *
 * Obtain the name depth for this context.
 */
static VALUE rxml_parser_context_name_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nameNr));
}

/*
 * call-seq:
 *    context.name_depth_max -> num
 *
 * Obtain the maximum name depth for this context.
 */
static VALUE rxml_parser_context_name_depth_max_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nameMax));
}

/*
 * call-seq:
 *    context.name_node -> "name"
 *
 * Obtain the name node for this context.
 */
static VALUE rxml_parser_context_name_node_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->name == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) ctxt->name));
}

/*
 * call-seq:
 *    context.name_tab -> ["name", ..., "name"]
 *
 * Obtain the name table for this context.
 */
static VALUE rxml_parser_context_name_tab_get(VALUE self)
{
  int i;
  xmlParserCtxtPtr ctxt;
  VALUE tab_ary;

  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->nameTab == NULL)
    return (Qnil);

  tab_ary = rb_ary_new();

  for (i = (ctxt->nameNr - 1); i >= 0; i--)
  {
    if (ctxt->nameTab[i] == NULL)
      continue;
    else
      rb_ary_push(tab_ary, rb_str_new2((const char*) ctxt->nameTab[i]));
  }

  return (tab_ary);
}

/*
 * call-seq:
 *    context.node_depth -> num
 *
 * Obtain the node depth for this context.
 */
static VALUE rxml_parser_context_node_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nodeNr));
}

/*
 * call-seq:
 *    context.node -> node
 *
 * Obtain the root node of this context.
 */
static VALUE rxml_parser_context_node_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->node == NULL)
    return (Qnil);
  else
    return (rxml_node_wrap(cXMLNode, ctxt->node));
}

/*
 * call-seq:
 *    context.node_depth_max -> num
 *
 * Obtain the maximum node depth for this context.
 */
static VALUE rxml_parser_context_node_depth_max_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->nodeMax));
}

/*
 * call-seq:
 *    context.num_chars -> num
 *
 * Obtain the number of characters in this context.
 */
static VALUE rxml_parser_context_num_chars_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (LONG2NUM(ctxt->nbChars));
}

/*
 * call-seq:
 *    context.replace_entities? -> (true|false)
 *
 * Determine whether external entity replacement is enabled in this
 * context.
 */
static VALUE rxml_parser_context_replace_entities_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->replaceEntities)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.replace_entities = true|false
 *
 * Control whether external entity replacement is enabled in this
 * context.
 */
static VALUE rxml_parser_context_replace_entities_set(VALUE self, VALUE bool)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (TYPE(bool) == T_FALSE)
  {
    ctxt->replaceEntities = 0;
    return (Qfalse);
  }
  else
  {
    ctxt->replaceEntities = 1;
    return (Qfalse);
  }
}

/*
 * call-seq:
 *    context.space_depth -> num
 *
 * Obtain the space depth for this context.
 */
static VALUE rxml_parser_context_space_depth_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->spaceNr));
}

/*
 * call-seq:
 *    context.space_depth -> num
 *
 * Obtain the maximum space depth for this context.
 */
static VALUE rxml_parser_context_space_depth_max_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  return (INT2NUM(ctxt->spaceMax));
}

/*
 * call-seq:
 *    context.subset_external? -> (true|false)
 *
 * Determine whether this context is a subset of an
 * external context.
 */
static VALUE rxml_parser_context_subset_external_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->inSubset == 2)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.subset_internal? -> (true|false)
 *
 * Determine whether this context is a subset of an
 * internal context.
 */
static VALUE rxml_parser_context_subset_internal_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->inSubset == 1)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.subset_internal_name -> "name"
 *
 * Obtain this context's subset name (valid only if
 * either of subset_external? or subset_internal?
 * is true).
 */
static VALUE rxml_parser_context_subset_name_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->intSubName == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) ctxt->intSubName));
}

/*
 * call-seq:
 *    context.subset_external_uri -> "uri"
 *
 * Obtain this context's external subset URI. (valid only if
 * either of subset_external? or subset_internal?
 * is true).
 */
static VALUE rxml_parser_context_subset_external_uri_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->extSubURI == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) ctxt->extSubURI));
}

/*
 * call-seq:
 *    context.subset_external_system_id -> "system_id"
 *
 * Obtain this context's external subset system identifier.
 * (valid only if either of subset_external? or subset_internal?
 * is true).
 */
static VALUE rxml_parser_context_subset_external_system_id_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->extSubSystem == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) ctxt->extSubSystem));
}

/*
 * call-seq:
 *    context.standalone? -> (true|false)
 *
 * Determine whether this is a standalone context.
 */
static VALUE rxml_parser_context_standalone_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->standalone)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.stats? -> (true|false)
 *
 * Determine whether this context maintains statistics.
 */
static VALUE rxml_parser_context_stats_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->record_info)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.valid? -> (true|false)
 *
 * Determine whether this context is valid.
 */
static VALUE rxml_parser_context_valid_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->valid)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.validate? -> (true|false)
 *
 * Determine whether validation is enabled in this context.
 */
static VALUE rxml_parser_context_validate_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->validate)
    return (Qtrue);
  else
    return (Qfalse);
}

/*
 * call-seq:
 *    context.version -> "version"
 *
 * Obtain this context's version identifier.
 */
static VALUE rxml_parser_context_version_get(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->version == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) ctxt->version));
}

/*
 * call-seq:
 *    context.well_formed? -> (true|false)
 *
 * Determine whether this context contains well-formed XML.
 */
static VALUE rxml_parser_context_well_formed_q(VALUE self)
{
  xmlParserCtxtPtr ctxt;
  Data_Get_Struct(self, xmlParserCtxt, ctxt);

  if (ctxt->wellFormed)
    return (Qtrue);
  else
    return (Qfalse);
}

void ruby_init_xml_parser_context(void)
{
  cXMLParserContext = rb_define_class_under(cXMLParser, "Context", rb_cObject);
  rb_undef_alloc_func(cXMLParserContext);

  rb_define_method(cXMLParserContext, "data_directory", rxml_parser_context_data_directory_get, 0);
  rb_define_method(cXMLParserContext, "depth", rxml_parser_context_depth_get, 0);
  rb_define_method(cXMLParserContext, "disable_sax?", rxml_parser_context_disable_sax_q, 0);
  rb_define_method(cXMLParserContext, "docbook?", rxml_parser_context_docbook_q, 0);
  rb_define_method(cXMLParserContext, "encoding", rxml_parser_context_encoding_get, 0);
  rb_define_method(cXMLParserContext, "errno", rxml_parser_context_errno_get, 0);
  rb_define_method(cXMLParserContext, "html?", rxml_parser_context_html_q, 0);
  rb_define_method(cXMLParserContext, "io_max_num_streams", rxml_parser_context_io_max_num_streams_get, 0);
  rb_define_method(cXMLParserContext, "io_num_streams", rxml_parser_context_io_num_streams_get, 0);
  rb_define_method(cXMLParserContext, "keep_blanks?", rxml_parser_context_keep_blanks_q, 0);
  rb_define_method(cXMLParserContext, "name_node", rxml_parser_context_name_node_get, 0);
  rb_define_method(cXMLParserContext, "name_depth", rxml_parser_context_name_depth_get, 0);
  rb_define_method(cXMLParserContext, "name_depth_max", rxml_parser_context_name_depth_max_get, 0);
  rb_define_method(cXMLParserContext, "name_tab", rxml_parser_context_name_tab_get, 0);
  rb_define_method(cXMLParserContext, "node", rxml_parser_context_node_get, 0);
  rb_define_method(cXMLParserContext, "node_depth", rxml_parser_context_node_depth_get, 0);
  rb_define_method(cXMLParserContext, "node_depth_max", rxml_parser_context_node_depth_max_get, 0);
  rb_define_method(cXMLParserContext, "num_chars", rxml_parser_context_num_chars_get, 0);
  rb_define_method(cXMLParserContext, "replace_entities?", rxml_parser_context_replace_entities_q, 0);
  rb_define_method(cXMLParserContext, "replace_entities=", rxml_parser_context_replace_entities_set, 1);
  rb_define_method(cXMLParserContext, "space_depth", rxml_parser_context_space_depth_get, 0);
  rb_define_method(cXMLParserContext, "space_depth_max", rxml_parser_context_space_depth_max_get, 0);
  rb_define_method(cXMLParserContext, "subset_external?", rxml_parser_context_subset_external_q, 0);
  rb_define_method(cXMLParserContext, "subset_external_system_id", rxml_parser_context_subset_external_system_id_get, 0);
  rb_define_method(cXMLParserContext, "subset_external_uri", rxml_parser_context_subset_external_uri_get, 0);
  rb_define_method(cXMLParserContext, "subset_internal?", rxml_parser_context_subset_internal_q, 0);
  rb_define_method(cXMLParserContext, "subset_internal_name", rxml_parser_context_subset_name_get, 0);
  rb_define_method(cXMLParserContext, "stats?", rxml_parser_context_stats_q, 0);
  rb_define_method(cXMLParserContext, "standalone?", rxml_parser_context_standalone_q, 0);
  rb_define_method(cXMLParserContext, "valid", rxml_parser_context_valid_q, 0);
  rb_define_method(cXMLParserContext, "validate?", rxml_parser_context_validate_q, 0);
  rb_define_method(cXMLParserContext, "version", rxml_parser_context_version_get, 0);
  rb_define_method(cXMLParserContext, "well_formed?", rxml_parser_context_well_formed_q, 0);
}
