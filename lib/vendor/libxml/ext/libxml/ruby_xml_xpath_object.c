/* $Id: $ */

#include "ruby_libxml.h"

/*
 * Document-class: LibXML::XML::XPath::Object
 *
 * A collection of nodes returned from the evaluation of an XML::XPath
 * or XML::XPointer expression.
 *
 */
VALUE cXMLXPathObject;

static xmlDocPtr rxml_xpath_object_doc(xmlXPathObjectPtr xpop)
{
  xmlDocPtr result = NULL;
  xmlNodePtr *nodes = NULL;

  if (xpop->type != XPATH_NODESET)
    return result;

  if (!xpop->nodesetval || !xpop->nodesetval->nodeTab)
    return result;

  nodes = xpop->nodesetval->nodeTab;

  if (!(*nodes))
    return result;

  return (*nodes)->doc;
}

static void rxml_xpath_object_mark(xmlXPathObjectPtr xpop)
{
  int i;

  if (xpop->type == XPATH_NODESET && xpop->nodesetval != NULL)
  {
    xmlDocPtr xdoc = rxml_xpath_object_doc(xpop);
    if (xdoc && xdoc->_private)
      rb_gc_mark((VALUE) xdoc->_private);

    for (i = 0; i < xpop->nodesetval->nodeNr; i++)
    {
      if (xpop->nodesetval->nodeTab[i]->_private)
        rb_gc_mark((VALUE) xpop->nodesetval->nodeTab[i]->_private);
    }
  }
}

static void rxml_xpath_object_free(xmlXPathObjectPtr xpop)
{
  /* Now free the xpath result but not underlying nodes
   since those belong to the document. */
  xmlXPathFreeNodeSetList(xpop);
}

VALUE rxml_xpath_object_wrap(xmlXPathObjectPtr xpop)
{
  VALUE rval;

  if (xpop == NULL)
    return Qnil;

  switch (xpop->type)
  {
  case XPATH_NODESET:
    rval = Data_Wrap_Struct(cXMLXPathObject, rxml_xpath_object_mark,
        rxml_xpath_object_free, xpop);

    break;
  case XPATH_BOOLEAN:
    if (xpop->boolval != 0)
      rval = Qtrue;
    else
      rval = Qfalse;

    xmlXPathFreeObject(xpop);
    break;
  case XPATH_NUMBER:
    rval = rb_float_new(xpop->floatval);

    xmlXPathFreeObject(xpop);
    break;
  case XPATH_STRING:
    rval = rb_str_new2((const char*)xpop->stringval);

    xmlXPathFreeObject(xpop);
    break;
  default:
    xmlXPathFreeObject(xpop);
    rval = Qnil;
  }
  return rval;
}

static VALUE rxml_xpath_object_tabref(xmlXPathObjectPtr xpop, int apos)
{

  if (apos < 0)
    apos = xpop->nodesetval->nodeNr + apos;

  if (apos < 0 || apos + 1 > xpop->nodesetval->nodeNr)
    return Qnil;

  switch (xpop->nodesetval->nodeTab[apos]->type)
  {
  case XML_ATTRIBUTE_NODE:
    return rxml_attr_wrap((xmlAttrPtr) xpop->nodesetval->nodeTab[apos]);
    break;
  default:
    return rxml_node_wrap(cXMLNode, xpop->nodesetval->nodeTab[apos]);
  }
}

/*
 * call-seq:
 *    xpath_object.to_a -> [node, ..., node]
 *
 * Obtain an array of the nodes in this set.
 */
static VALUE rxml_xpath_object_to_a(VALUE self)
{
  VALUE set_ary, nodeobj;
  xmlXPathObjectPtr xpop;
  int i;

  Data_Get_Struct(self, xmlXPathObject, xpop);

  set_ary = rb_ary_new();
  if (!((xpop->nodesetval == NULL) || (xpop->nodesetval->nodeNr == 0)))
  {
    for (i = 0; i < xpop->nodesetval->nodeNr; i++)
    {
      nodeobj = rxml_xpath_object_tabref(xpop, i);
      rb_ary_push(set_ary, nodeobj);
    }
  }

  return (set_ary);
}

/*
 * call-seq:
 *    xpath_object.empty? -> (true|false)
 *
 * Determine whether this nodeset is empty (contains no nodes).
 */
static VALUE rxml_xpath_object_empty_q(VALUE self)
{
  xmlXPathObjectPtr xpop;

  Data_Get_Struct(self, xmlXPathObject, xpop);

  if (xpop->type != XPATH_NODESET)
    return Qnil;

  return (xpop->nodesetval == NULL || xpop->nodesetval->nodeNr <= 0) ? Qtrue
      : Qfalse;
}

/*
 * call-seq:
 *    xpath_object.each { |node| ... } -> self
 *
 * Call the supplied block for each node in this set.
 */
static VALUE rxml_xpath_object_each(VALUE self)
{
  xmlXPathObjectPtr xpop;
  int i;

  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return Qnil;

  Data_Get_Struct(self, xmlXPathObject, xpop);

  for (i = 0; i < xpop->nodesetval->nodeNr; i++)
  {
    rb_yield(rxml_xpath_object_tabref(xpop, i));
  }
  return (self);
}

/*
 * call-seq:
 *    xpath_object.first -> node
 *
 * Returns the first node in this node set, or nil if none exist.
 */
static VALUE rxml_xpath_object_first(VALUE self)
{
  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return Qnil;

  return rxml_xpath_object_tabref((xmlXPathObjectPtr) DATA_PTR(self), 0);
}

/*
 * call-seq:
 * xpath_object[i] -> node
 *
 * array index into set of nodes
 */
static VALUE rxml_xpath_object_aref(VALUE self, VALUE aref)
{
  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return Qnil;

  return rxml_xpath_object_tabref((xmlXPathObjectPtr) DATA_PTR(self), NUM2INT(
      aref));
}

/*
 * call-seq:
 *    xpath_object.length -> num
 *
 * Obtain the length of the nodesetval node list.
 */
static VALUE rxml_xpath_object_length(VALUE self)
{
  xmlXPathObjectPtr xpop;

  if (rxml_xpath_object_empty_q(self) == Qtrue)
    return INT2FIX(0);

  Data_Get_Struct(self, xmlXPathObject, xpop);

  return INT2NUM(xpop->nodesetval->nodeNr);
}

/*
 * call-seq:
 *    xpath_object.xpath_type -> int
 *
 * Returns the XPath type of the result object.
 * Possible values are defined as constants
 * on the XML::XPath class and include:
 *
 * * XML::XPath::UNDEFINED
 * * XML::XPath::NODESET
 * * XML::XPath::BOOLEAN
 * * XML::XPath::NUMBER
 * * XML::XPath::STRING
 * * XML::XPath::POINT
 * * XML::XPath::RANGE
 * * XML::XPath::LOCATIONSET
 * * XML::XPath::USERS
 * * XML::XPath::XSLT_TREE
 */
static VALUE rxml_xpath_object_get_type(VALUE self)
{
  xmlXPathObjectPtr xpop;

  Data_Get_Struct(self, xmlXPathObject, xpop);

  return INT2FIX(xpop->type);
}

/*
 * call-seq:
 *    xpath_object.string -> String
 *
 * Returns the original XPath expression as a string.
 */
static VALUE rxml_xpath_object_string(VALUE self)
{
  xmlXPathObjectPtr xpop;

  Data_Get_Struct(self, xmlXPathObject, xpop);

  if (xpop->stringval == NULL)
    return Qnil;

  return rb_str_new2((const char*) xpop->stringval);
}

/*
 * call-seq:
 *    nodes.debug -> (true|false)
 *
 * Dump libxml debugging information to stdout.
 * Requires Libxml be compiled with debugging enabled.
 */
static VALUE rxml_xpath_object_debug(VALUE self)
{
#ifdef LIBXML_DEBUG_ENABLED
  xmlXPathObjectPtr xpop;
  Data_Get_Struct(self, xmlXPathObject, xpop);
  xmlXPathDebugDumpObject(stdout, xpop, 0);
  return Qtrue;
#else
  rb_warn("libxml was compiled without debugging support.")
  return Qfalse;
#endif
}

void ruby_init_xml_xpath_object(void)
{
  cXMLXPathObject = rb_define_class_under(mXPath, "Object", rb_cObject);
  rb_include_module(cXMLXPathObject, rb_mEnumerable);
  rb_define_attr(cXMLXPathObject, "context", 1, 0);
  rb_define_method(cXMLXPathObject, "each", rxml_xpath_object_each, 0);
  rb_define_method(cXMLXPathObject, "xpath_type", rxml_xpath_object_get_type, 0);
  rb_define_method(cXMLXPathObject, "empty?", rxml_xpath_object_empty_q, 0);
  rb_define_method(cXMLXPathObject, "first", rxml_xpath_object_first, 0);
  rb_define_method(cXMLXPathObject, "length", rxml_xpath_object_length, 0);
  rb_define_method(cXMLXPathObject, "size", rxml_xpath_object_length, 0);
  rb_define_method(cXMLXPathObject, "to_a", rxml_xpath_object_to_a, 0);
  rb_define_method(cXMLXPathObject, "[]", rxml_xpath_object_aref, 1);
  rb_define_method(cXMLXPathObject, "string", rxml_xpath_object_string, 0);
  rb_define_method(cXMLXPathObject, "debug", rxml_xpath_object_debug, 0);
}
