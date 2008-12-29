#include "ruby_libxml.h"
#include "ruby_xml_node.h"

VALUE cXMLNode;

/* Document-class: LibXML::XML::Node
 *
 * Nodes are the primary objects that make up an XML document.
 * The node class represents most node types that are found in
 * an XML document (but not Attributes, see LibXML::XML::Attribute).
 * It exposes libxml's full API for creating, querying
 * moving and deleting node objects.  Many of these methods are
 * documented in the DOM Level 3 specification found at:
 * http://www.w3.org/TR/DOM-Level-3-Core/. */

static VALUE rxml_node_content_set(VALUE self, VALUE content);

VALUE check_string_or_symbol(VALUE val)
{
  if (TYPE(val) != T_STRING && TYPE(val) != T_SYMBOL)
  {
    rb_raise(rb_eTypeError,
        "wrong argument type %s (expected String or Symbol)", rb_obj_classname(
            val));
  }
  return rb_obj_as_string(val);
}

/*
 * memory2 implementation: xmlNode->_private holds a reference
 * to the wrapping ruby object VALUE when there is one.
 * traversal for marking is upward, and top levels are marked
 * through and lower level mark entry.
 *
 * All ruby retrieval for an xml
 * node will result in the same ruby instance. When all handles to them
 * go out of scope, then ruby_xfree gets called and _private is set to NULL.
 * If the xmlNode has no parent or document, then call xmlFree.
 */
void rxml_node2_free(xmlNodePtr xnode)
{
  /* Set _private to NULL so that we won't reuse the
   same, freed, Ruby wrapper object later.*/
  xnode->_private = NULL;

  if (xnode->doc == NULL && xnode->parent == NULL)
    xmlFreeNode(xnode);
}

void rxml_node_mark_common(xmlNodePtr xnode)
{
  if (xnode->parent == NULL)
    return;

  if (xnode->doc != NULL)
  {
    if (xnode->doc->_private == NULL)
      rb_bug("XmlNode Doc is not bound! (%s:%d)", __FILE__,__LINE__);
    rb_gc_mark((VALUE) xnode->doc->_private);
  }
  else
  {
    while (xnode->parent != NULL)
      xnode = xnode->parent;

    if (xnode->_private == NULL)
      rb_warning("XmlNode Root Parent is not bound! (%s:%d)", __FILE__,__LINE__);
    else
      rb_gc_mark((VALUE) xnode->_private);
  }
}

void rxml_node_mark(xmlNodePtr xnode)
{
  if (xnode == NULL)
    return;

  if (xnode->_private == NULL)
  {
    rb_warning("XmlNode is not bound! (%s:%d)", __FILE__, __LINE__);
    return;
  }

  rxml_node_mark_common(xnode);
}

VALUE rxml_node_wrap(VALUE klass, xmlNodePtr xnode)
{
  VALUE obj;

  // This node is already wrapped
  if (xnode->_private != NULL)
  {
    return (VALUE) xnode->_private;
  }

  obj = Data_Wrap_Struct(klass, rxml_node_mark, rxml_node2_free, xnode);

  xnode->_private = (void*) obj;
  return obj;
}

static VALUE rxml_node_alloc(VALUE klass)
{
  return Data_Wrap_Struct(klass, rxml_node_mark, rxml_node2_free, NULL);
}

/*
 * call-seq:
 *    XML::Node.new_cdata(content = nil) -> XML::Node
 *
 * Create a new #CDATA node, optionally setting
 * the node's content.
 */
static VALUE rxml_node_new_cdata(int argc, VALUE *argv, VALUE klass)
{
  VALUE content = Qnil;
  xmlNodePtr xnode;

  rb_scan_args(argc, argv, "01", &content);

  if (NIL_P(content))
  {
    xnode = xmlNewCDataBlock(NULL, NULL, 0);
  }
  else
  {
    content = rb_obj_as_string(content);
    xnode = xmlNewCDataBlock(NULL, (xmlChar*) StringValuePtr(content),
        RSTRING_LEN(content));
  }

  if (xnode == NULL)
    rxml_raise(&xmlLastError);

  return rxml_node_wrap(klass, xnode);
}

/*
 * call-seq:
 *    XML::Node.new_comment(content = nil) -> XML::Node
 *
 * Create a new comment node, optionally setting
 * the node's content.
 *
 */
static VALUE rxml_node_new_comment(int argc, VALUE *argv, VALUE klass)
{
  VALUE content = Qnil;
  xmlNodePtr xnode;

  rb_scan_args(argc, argv, "01", &content);

  if (NIL_P(content))
  {
    xnode = xmlNewComment(NULL);
  }
  else
  {
    content = rb_obj_as_string(content);
    xnode = xmlNewComment((xmlChar*) StringValueCStr(content));
  }

  if (xnode == NULL)
    rxml_raise(&xmlLastError);

  return rxml_node_wrap(klass, xnode);
}

/*
 * call-seq:
 *    XML::Node.new_text(content) -> XML::Node
 *
 * Create a new text node.
 *
 */
static VALUE rxml_node_new_text(VALUE klass, VALUE content)
{
  xmlNodePtr xnode;
  Check_Type(content, T_STRING);
  content = rb_obj_as_string(content);

  xnode = xmlNewText((xmlChar*) StringValueCStr(content));

  if (xnode == NULL)
    rxml_raise(&xmlLastError);

  return rxml_node_wrap(klass, xnode);
}

/*
 * call-seq:
 *    XML::Node.initialize(name, content = nil, namespace = nil) -> XML::Node
 *
 * Creates a new element with the specified name, content and
 * namespace. The content and namespace may be nil.
 */
static VALUE rxml_node_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE name;
  VALUE content;
  VALUE ns;
  xmlNodePtr xnode = NULL;
  xmlNsPtr xns = NULL;

  rb_scan_args(argc, argv, "12", &name, &content, &ns);

  name = check_string_or_symbol(name);

  if (!NIL_P(ns))
    Data_Get_Struct(ns, xmlNs, xns);

  xnode = xmlNewNode(xns, (xmlChar*) StringValuePtr(name));
  xnode->_private = (void*) self;
  DATA_PTR( self) = xnode;

  if (!NIL_P(content))
    rxml_node_content_set(self, content);

  return self;
}

/*
 * call-seq:
 *    node.base -> "uri"
 *
 * Obtain this node's base URI.
 */
static VALUE rxml_node_base_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar* base_uri;
  VALUE result = Qnil;

  Data_Get_Struct(self, xmlNode, xnode);

  if (xnode->doc == NULL)
    return (result);

  base_uri = xmlNodeGetBase(xnode->doc, xnode);
  if (base_uri)
  {
    result = rb_str_new2((const char*) base_uri);
    xmlFree(base_uri);
  }

  return (result);
}

// TODO node_base_set should support setting back to nil

/*
 * call-seq:
 *    node.base = "uri"
 *
 * Set this node's base URI.
 */
static VALUE rxml_node_base_set(VALUE self, VALUE uri)
{
  xmlNodePtr xnode;

  Check_Type(uri, T_STRING);
  Data_Get_Struct(self, xmlNode, xnode);
  if (xnode->doc == NULL)
    return (Qnil);

  xmlNodeSetBase(xnode, (xmlChar*) StringValuePtr(uri));
  return (Qtrue);
}

/*
 * call-seq:
 *    node.content -> "string"
 *
 * Obtain this node's content as a string.
 */
static VALUE rxml_node_content_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar *content;
  VALUE result = Qnil;

  Data_Get_Struct(self, xmlNode, xnode);
  content = xmlNodeGetContent(xnode);
  if (content)
  {
    result = rb_str_new2((const char *) content);
    xmlFree(content);
  }

  return result;
}

/*
 * call-seq:
 *    node.content = "string"
 *
 * Set this node's content to the specified string.
 */
static VALUE rxml_node_content_set(VALUE self, VALUE content)
{
  xmlNodePtr xnode;

  Check_Type(content, T_STRING);
  Data_Get_Struct(self, xmlNode, xnode);
  // XXX docs indicate need for escaping entites, need to be done? danj
  xmlNodeSetContent(xnode, (xmlChar*) StringValuePtr(content));
  return (Qtrue);
}

/*
 * call-seq:
 *    node.content_stripped -> "string"
 *
 * Obtain this node's stripped content.
 *
 * *Deprecated*: Stripped content can be obtained via the
 * +content+ method.
 */
static VALUE rxml_node_content_stripped_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar* content;
  VALUE result = Qnil;

  Data_Get_Struct(self, xmlNode, xnode);

  if (!xnode->content)
    return result;

  content = xmlNodeGetContent(xnode);
  if (content)
  {
    result = rb_str_new2((const char*) content);
    xmlFree(content);
  }
  return (result);
}

/*
 * call-seq:
 *    node.debug -> true|false
 *
 * Print libxml debugging information to stdout.
 * Requires that libxml was compiled with debugging enabled.
*/
static VALUE rxml_node_debug(VALUE self)
{
#ifdef LIBXML_DEBUG_ENABLED
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);
  xmlDebugDumpNode(NULL, xnode, 2);
  return Qtrue;
#else
  rb_warn("libxml was compiled without debugging support.")
  return Qfalse;
#endif
}

/*
 * call-seq:
 *    node.first -> XML::Node
 *
 * Returns this node's first child node if any.
 */
static VALUE rxml_node_first_get(VALUE self)
{
  xmlNodePtr xnode;

  Data_Get_Struct(self, xmlNode, xnode);

  if (xnode->children)
    return (rxml_node_wrap(cXMLNode, xnode->children));
  else
    return (Qnil);
}

/*
 * underlying for child_set and child_add, difference being
 * former raises on implicit copy, latter does not.
 */
static VALUE rxml_node_child_set_aux(VALUE self, VALUE rnode)
{
  xmlNodePtr pnode, chld, ret;

  if (rb_obj_is_kind_of(rnode, cXMLNode) == Qfalse)
    rb_raise(rb_eTypeError, "Must pass an XML::Node object");

  Data_Get_Struct(self, xmlNode, pnode);
  Data_Get_Struct(rnode, xmlNode, chld);

  if (chld->parent != NULL || chld->doc != NULL)
    rb_raise(
        rb_eRuntimeError,
        "Cannot move a node from one document to another with child= or <<.  First copy the node before moving it.");

  ret = xmlAddChild(pnode, chld);
  if (ret == NULL)
  {
    rxml_raise(&xmlLastError);
  }
  else if (ret == chld)
  {
    /* child was added whole to parent and we need to return it as a new object */
    return rxml_node_wrap(cXMLNode, chld);
  }
  /* else */
  /* If it was a text node, then ret should be parent->last, so we will just return ret. */
  return rxml_node_wrap(cXMLNode, ret);
}

/*
 * call-seq:
 *    node.child = node
 *
 * Set a child node for this node. Also called for <<
 */
static VALUE rxml_node_child_set(VALUE self, VALUE rnode)
{
  return rxml_node_child_set_aux(self, rnode);
}

/*
 * call-seq:
 *    node << ("string" | node) -> XML::Node
 *
 * Add the specified string or XML::Node to this node's
 * content.  The returned node is the node that was
 * added and not self, thereby allowing << calls to
 * be chained.
 */
static VALUE rxml_node_content_add(VALUE self, VALUE obj)
{
  xmlNodePtr xnode;
  VALUE str;

  Data_Get_Struct(self, xmlNode, xnode);
  /* XXX This should only be legal for a CDATA type node, I think,
   * resulting in a merge of content, as if a string were passed
   * danj 070827
   */
  if (rb_obj_is_kind_of(obj, cXMLNode))
  {
    rxml_node_child_set(self, obj);
  }
  else
  {
    str = rb_obj_as_string(obj);
    if (NIL_P(str) || TYPE(str) != T_STRING)
      rb_raise(rb_eTypeError, "invalid argument: must be string or XML::Node");

    xmlNodeAddContent(xnode, (xmlChar*) StringValuePtr(str));
  }
  return (self);
}

/*
 * call-seq:
 *    node.child_add(node)
 *
 * Set a child node for this node.
 */
static VALUE rxml_node_child_add(VALUE self, VALUE rnode)
{
  return rxml_node_child_set_aux(self, rnode);
}

/*
 * call-seq:
 *    node.doc -> document
 *
 * Obtain the XML::Document this node belongs to.
 */
static VALUE rxml_node_doc(VALUE self)
{
  xmlNodePtr xnode;
  xmlDocPtr doc = NULL;

  Data_Get_Struct(self, xmlNode, xnode);

  switch (xnode->type)
  {
  case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
    case XML_DOCB_DOCUMENT_NODE:
#endif
  case XML_HTML_DOCUMENT_NODE:
    doc = NULL;
    break;
  case XML_ATTRIBUTE_NODE:
  {
    xmlAttrPtr attr = (xmlAttrPtr) xnode;
    doc = attr->doc;
    break;
  }
  case XML_NAMESPACE_DECL:
    doc = NULL;
    break;
  default:
    doc = xnode->doc;
    break;
  }

  if (doc == NULL)
    return (Qnil);

  if (doc->_private == NULL)
    rb_raise(rb_eRuntimeError, "existing document object has no ruby-instance");

  return (VALUE) doc->_private;
}

/*
 * call-seq:
 *    node.to_s -> "string"
 *    node.to_s(:indent => true, :encoding => 'UTF-8', :level => 0) -> "string"
 *
 * Converts a node, and all of its children, to a string representation.
 * You may provide an optional hash table to control how the string is 
 * generated.  Valid options are:
 * 
 * :indent - Specifies if the string should be indented.  The default value
 * is true.  Note that indentation is only added if both :indent is
 * true and XML.indent_tree_output is true.  If :indent is set to false,
 * then both indentation and line feeds are removed from the result.
 *
 * :level  - Specifies the indentation level.  The amount of indentation
 * is equal to the (level * number_spaces) + number_spaces, where libxml
 * defaults the number of spaces to 2.  Thus a level of 0 results in
 * 2 spaces, level 1 results in 4 spaces, level 2 results in 6 spaces, etc.
 *
 * :encoding - Specifies the output encoding of the string.  It
 * defaults to XML::Input::UTF8.  To change it, use one of the
 * XML::Input encoding constants. */

static VALUE rxml_node_to_s(int argc, VALUE *argv, VALUE self)
{
  VALUE options = Qnil;
  xmlNodePtr xnode;
  xmlCharEncodingHandlerPtr encodingHandler;
  xmlOutputBufferPtr output;

  int level = 0;
  int indent = 1;
  const char *encoding = "UTF-8";

  rb_scan_args(argc, argv, "01", &options);

  if (!NIL_P(options))
  {
    VALUE rencoding, rindent, rlevel;
    Check_Type(options, T_HASH);
    rencoding = rb_hash_aref(options, ID2SYM(rb_intern("encoding")));
    rindent = rb_hash_aref(options, ID2SYM(rb_intern("indent")));
    rlevel = rb_hash_aref(options, ID2SYM(rb_intern("level")));

    if (rindent == Qfalse)
      indent = 0;

    if (rlevel != Qnil)
      level = NUM2INT(rlevel);

    if (rencoding != Qnil)
      encoding = RSTRING_PTR(rxml_input_encoding_to_s(cXMLInput, rencoding));
  }

  encodingHandler = xmlFindCharEncodingHandler(encoding);
  output = xmlAllocOutputBuffer(encodingHandler);

  Data_Get_Struct(self, xmlNode, xnode);
  xmlNodeDumpOutput(output, xnode->doc, xnode, level, indent, encoding);
  xmlOutputBufferFlush(output);

  if (output->conv)
    return rb_str_new2((const char*) output->conv->content);
  else
    return rb_str_new2((const char*) output->buffer->content);
}


/*
 * call-seq:
 *    node.each -> XML::Node
 *
 * Iterates over this node's children, including text
 * nodes, element nodes, etc.  If you wish to iterate
 * only over child elements, use XML::Node#each_element.
 *
 *  doc = XML::Document.new('model/books.xml')
 *  doc.root.each {|node| puts node}
 */
static VALUE rxml_node_each(VALUE self)
{
  xmlNodePtr xnode;
  xmlNodePtr xchild;
  Data_Get_Struct(self, xmlNode, xnode);

  xchild = xnode->children;

  while (xchild)
  {
    rb_yield(rxml_node_wrap(cXMLNode, xchild));
    xchild = xchild->next;
  }
  return Qnil;
}

/*
 * call-seq:
 *    node.empty? -> (true|false)
 *
 * Determine whether this node is empty.
 */
static VALUE rxml_node_empty_q(VALUE self)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);
  if (xnode == NULL)
    return (Qnil);

  return ((xmlIsBlankNode(xnode) == 1) ? Qtrue : Qfalse);
}


/*
 * call-seq:
 *    node.eql?(other_node) => (true|false)
 *
 * Test equality between the two nodes. Two nodes are equal
 * if they are the same node or have the same XML representation.*/
static VALUE rxml_node_eql_q(VALUE self, VALUE other)
{
if(self == other)
{
  return Qtrue;
}
else if (NIL_P(other))
{
  return Qfalse;
}
else
{
  VALUE self_xml;
  VALUE other_xml;

  if (rb_obj_is_kind_of(other, cXMLNode) == Qfalse)
  rb_raise(rb_eTypeError, "Nodes can only be compared against other nodes");

  self_xml = rxml_node_to_s(0, NULL, self);
  other_xml = rxml_node_to_s(0, NULL, other);
  return(rb_funcall(self_xml, rb_intern("=="), 1, other_xml));
}
}

/*
 * call-seq:
 *    node.lang -> "string"
 *
 * Obtain the language set for this node, if any.
 * This is set in XML via the xml:lang attribute.
 */
static VALUE rxml_node_lang_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar *lang;
  VALUE result = Qnil;

  Data_Get_Struct(self, xmlNode, xnode);
  lang = xmlNodeGetLang(xnode);

  if (lang)
  {
    result = rb_str_new2((const char*) lang);
    xmlFree(lang);
  }

  return (result);
}

// TODO node_lang_set should support setting back to nil

/*
 * call-seq:
 *    node.lang = "string"
 *
 * Set the language for this node. This affects the value
 * of the xml:lang attribute.
 */
static VALUE rxml_node_lang_set(VALUE self, VALUE lang)
{
  xmlNodePtr xnode;

  Check_Type(lang, T_STRING);
  Data_Get_Struct(self, xmlNode, xnode);
  xmlNodeSetLang(xnode, (xmlChar*) StringValuePtr(lang));

  return (Qtrue);
}

/*
 * call-seq:
 *    node.last -> XML::Node
 *
 * Obtain the last child node of this node, if any.
 */
static VALUE rxml_node_last_get(VALUE self)
{
  xmlNodePtr xnode;

  Data_Get_Struct(self, xmlNode, xnode);

  if (xnode->last)
    return (rxml_node_wrap(cXMLNode, xnode->last));
  else
    return (Qnil);
}

/*
 * call-seq:
 *    node.line_num -> num
 *
 * Obtain the line number (in the XML document) that this
 * node was read from. If +default_line_numbers+ is set
 * false (the default), this method returns zero.
 */
static VALUE rxml_node_line_num(VALUE self)
{
  xmlNodePtr xnode;
  long line_num;
  Data_Get_Struct(self, xmlNode, xnode);

  if (!xmlLineNumbersDefaultValue)
    rb_warn(
        "Line numbers were not retained: use XML::Parser::default_line_numbers=true");

  line_num = xmlGetLineNo(xnode);
  if (line_num == -1)
    return (Qnil);
  else
    return (INT2NUM((long) line_num));
}

/*
 * call-seq:
 *    node.xlink? -> (true|false)
 *
 * Determine whether this node is an xlink node.
 */
static VALUE rxml_node_xlink_q(VALUE self)
{
  xmlNodePtr xnode;
  xlinkType xlt;

  Data_Get_Struct(self, xmlNode, xnode);
  xlt = xlinkIsLink(xnode->doc, xnode);

  if (xlt == XLINK_TYPE_NONE)
    return (Qfalse);
  else
    return (Qtrue);
}

/*
 * call-seq:
 *    node.xlink_type -> num
 *
 * Obtain the type identifier for this xlink, if applicable.
 * If this is not an xlink node (see +xlink?+), will return
 * nil.
 */
static VALUE rxml_node_xlink_type(VALUE self)
{
  xmlNodePtr xnode;
  xlinkType xlt;

  Data_Get_Struct(self, xmlNode, xnode);
  xlt = xlinkIsLink(xnode->doc, xnode);

  if (xlt == XLINK_TYPE_NONE)
    return (Qnil);
  else
    return (INT2NUM(xlt));
}

/*
 * call-seq:
 *    node.xlink_type_name -> "string"
 *
 * Obtain the type name for this xlink, if applicable.
 * If this is not an xlink node (see +xlink?+), will return
 * nil.
 */
static VALUE rxml_node_xlink_type_name(VALUE self)
{
  xmlNodePtr xnode;
  xlinkType xlt;

  Data_Get_Struct(self, xmlNode, xnode);
  xlt = xlinkIsLink(xnode->doc, xnode);

  switch (xlt)
  {
  case XLINK_TYPE_NONE:
    return (Qnil);
  case XLINK_TYPE_SIMPLE:
    return (rb_str_new2("simple"));
  case XLINK_TYPE_EXTENDED:
    return (rb_str_new2("extended"));
  case XLINK_TYPE_EXTENDED_SET:
    return (rb_str_new2("extended_set"));
  default:
    rb_fatal("Unknowng xlink type, %d", xlt);
  }
}

/*
 * call-seq:
 *    node.name -> "string"
 *
 * Obtain this node's name.
 */
static VALUE rxml_node_name_get(VALUE self)
{
  xmlNodePtr xnode;
  const xmlChar *name;

  Data_Get_Struct(self, xmlNode, xnode);

  switch (xnode->type)
  {
  case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
    case XML_DOCB_DOCUMENT_NODE:
#endif
  case XML_HTML_DOCUMENT_NODE:
  {
    xmlDocPtr doc = (xmlDocPtr) xnode;
    name = doc->URL;
    break;
  }
  case XML_ATTRIBUTE_NODE:
  {
    xmlAttrPtr attr = (xmlAttrPtr) xnode;
    name = attr->name;
    break;
  }
  case XML_NAMESPACE_DECL:
  {
    xmlNsPtr ns = (xmlNsPtr) xnode;
    name = ns->prefix;
    break;
  }
  default:
    name = xnode->name;
    break;
  }

  if (xnode->name == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) name));
}

/*
 * call-seq:
 *    node.name = "string"
 *
 * Set this node's name.
 */
static VALUE rxml_node_name_set(VALUE self, VALUE name)
{
  xmlNodePtr xnode;

  Check_Type(name, T_STRING);
  Data_Get_Struct(self, xmlNode, xnode);
  xmlNodeSetName(xnode, (xmlChar*) StringValuePtr(name));
  return (Qtrue);
}

/*
 * call-seq:
 *    node.next -> XML::Node
 *
 * Obtain the next sibling node, if any.
 */
static VALUE rxml_node_next_get(VALUE self)
{
  xmlNodePtr xnode;

  Data_Get_Struct(self, xmlNode, xnode);

  if (xnode->next)
    return (rxml_node_wrap(cXMLNode, xnode->next));
  else
    return (Qnil);
}

/*
 * call-seq:
 *    node.next = node
 *
 * Insert the specified node as this node's next sibling.
 */
static VALUE rxml_node_next_set(VALUE self, VALUE rnode)
{
  xmlNodePtr cnode, pnode, ret;

  if (rb_obj_is_kind_of(rnode, cXMLNode) == Qfalse)
    rb_raise(rb_eTypeError, "Must pass an XML::Node object");

  Data_Get_Struct(self, xmlNode, pnode);
  Data_Get_Struct(rnode, xmlNode, cnode);

  ret = xmlAddNextSibling(pnode, cnode);
  if (ret == NULL)
    rxml_raise(&xmlLastError);

  return (rxml_node_wrap(cXMLNode, ret));
}

/*
 * call-seq:
 *    node.parent -> XML::Node
 *
 * Obtain this node's parent node, if any.
 */
static VALUE rxml_node_parent_get(VALUE self)
{
  xmlNodePtr xnode;

  Data_Get_Struct(self, xmlNode, xnode);

  if (xnode->parent)
    return (rxml_node_wrap(cXMLNode, xnode->parent));
  else
    return (Qnil);
}

/*
 * call-seq:
 *    node.path -> path
 *
 * Obtain this node's path.
 */
static VALUE rxml_node_path(VALUE self)
{
  xmlNodePtr xnode;
  xmlChar *path;

  Data_Get_Struct(self, xmlNode, xnode);
  path = xmlGetNodePath(xnode);

  if (path == NULL)
    return (Qnil);
  else
    return (rb_str_new2((const char*) path));
}

/*
 * call-seq:
 *    node.pointer -> XML::NodeSet
 *
 * Evaluates an XPointer expression relative to this node.
 */
static VALUE rxml_node_pointer(VALUE self, VALUE xptr_str)
{
  return (rxml_xpointer_point2(self, xptr_str));
}

/*
 * call-seq:
 *    node.prev -> XML::Node
 *
 * Obtain the previous sibling, if any.
 */
static VALUE rxml_node_prev_get(VALUE self)
{
  xmlNodePtr xnode;
  xmlNodePtr node;
  Data_Get_Struct(self, xmlNode, xnode);

  switch (xnode->type)
  {
  case XML_DOCUMENT_NODE:
#ifdef LIBXML_DOCB_ENABLED
    case XML_DOCB_DOCUMENT_NODE:
#endif
  case XML_HTML_DOCUMENT_NODE:
  case XML_NAMESPACE_DECL:
    node = NULL;
    break;
  case XML_ATTRIBUTE_NODE:
  {
    xmlAttrPtr attr = (xmlAttrPtr) xnode;
    node = (xmlNodePtr) attr->prev;
  }
    break;
  default:
    node = xnode->prev;
    break;
  }

  if (node == NULL)
    return (Qnil);
  else
    return (rxml_node_wrap(cXMLNode, node));
}

/*
 * call-seq:
 *    node.prev = node
 *
 * Insert the specified node as this node's previous sibling.
 */
static VALUE rxml_node_prev_set(VALUE self, VALUE rnode)
{
  xmlNodePtr cnode, pnode, ret;

  if (rb_obj_is_kind_of(rnode, cXMLNode) == Qfalse)
    rb_raise(rb_eTypeError, "Must pass an XML::Node object");

  Data_Get_Struct(self, xmlNode, pnode);
  Data_Get_Struct(rnode, xmlNode, cnode);

  ret = xmlAddPrevSibling(pnode, cnode);
  if (ret == NULL)
    rxml_raise(&xmlLastError);

  return (rxml_node_wrap(cXMLNode, ret));
}

/*
 * call-seq:
 *    node.attributes -> attributes
 *
 * Returns the XML::Attributes for this node.
 */
static VALUE rxml_node_attributes_get(VALUE self)
{
  xmlNodePtr xnode;

  Data_Get_Struct(self, xmlNode, xnode);
  return rxml_attributes_new(xnode);
}

/*
 * call-seq:
 *    node.property("name") -> "string"
 *    node["name"]          -> "string"
 *
 * Obtain the named pyroperty.
 */
static VALUE rxml_node_attribute_get(VALUE self, VALUE name)
{
  VALUE attributes = rxml_node_attributes_get(self);
  return rxml_attributes_attribute_get(attributes, name);
}

/*
 * call-seq:
 *    node["name"] = "string"
 *
 * Set the named property.
 */
static VALUE rxml_node_property_set(VALUE self, VALUE name, VALUE value)
{
  VALUE attributes = rxml_node_attributes_get(self);
  return rxml_attributes_attribute_set(attributes, name, value);
}

/*
 * call-seq:
 *    node.remove! -> node
 *
 * Removes this node and its children from its
 * document tree by setting its document,
 * parent and siblings to nil.  You can add
 * the returned node back into a document.
 * Otherwise, the node will be freed once
 * any references to it go out of scope. */

static VALUE rxml_node_remove_ex(VALUE self)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);
  /* Unlink the node from its parent. */
  xmlUnlinkNode(xnode);
  /* Now set the nodes parent to nil so it can
   be freed if the reference to it goes out of scope*/
  xmlSetTreeDoc(xnode, NULL);

  /* Now return the removed node so the user can
   do something wiht it.*/
  return self;
}

/*
 * call-seq:
 *    node.sibling(node) -> XML::Node
 *
 * Add the specified node as a sibling of this node.
 */
static VALUE rxml_node_sibling_set(VALUE self, VALUE rnode)
{
  xmlNodePtr cnode, pnode, ret;
  VALUE obj;

  if (rb_obj_is_kind_of(rnode, cXMLNode) == Qfalse)
    rb_raise(rb_eTypeError, "Must pass an XML::Node object");

  Data_Get_Struct(self, xmlNode, pnode);
  Data_Get_Struct(rnode, xmlNode, cnode);

  ret = xmlAddSibling(pnode, cnode);
  if (ret == NULL)
    rxml_raise(&xmlLastError);

  if (ret->_private == NULL)
    obj = rxml_node_wrap(cXMLNode, ret);
  else
    obj = (VALUE) ret->_private;

  return obj;
}

/*
 * call-seq:
 *    node.space_preserve -> (true|false)
 *
 * Determine whether this node preserves whitespace.
 */
static VALUE rxml_node_space_preserve_get(VALUE self)
{
  xmlNodePtr xnode;

  Data_Get_Struct(self, xmlNode, xnode);
  return (INT2NUM(xmlNodeGetSpacePreserve(xnode)));
}

/*
 * call-seq:
 *    node.space_preserve = true|false
 *
 * Control whether this node preserves whitespace.
 */
static VALUE rxml_node_space_preserve_set(VALUE self, VALUE bool)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);

  if (TYPE(bool) == T_FALSE)
    xmlNodeSetSpacePreserve(xnode, 1);
  else
    xmlNodeSetSpacePreserve(xnode, 0);

  return (Qnil);
}

/*
 * call-seq:
 *    node.type -> num
 *
 * Obtain this node's type identifier.
 */
static VALUE rxml_node_type(VALUE self)
{
  xmlNodePtr xnode;
  Data_Get_Struct(self, xmlNode, xnode);
  return (INT2NUM(xnode->type));
}

/*
 * call-seq:
 *    node.copy -> XML::Node
 *
 * Creates a copy of this node.  To create a
 * shallow copy set the deep parameter to false.
 * To create a deep copy set the deep parameter
 * to true.
 *
 */
static VALUE rxml_node_copy(VALUE self, VALUE deep)
{
  xmlNodePtr xnode;
  xmlNodePtr xcopy;
  int recursive = (deep == Qnil || deep == Qfalse) ? 0 : 1;
  Data_Get_Struct(self, xmlNode, xnode);

  xcopy = xmlCopyNode(xnode, recursive);

  if (xcopy)
    return rxml_node_wrap(cXMLNode, xcopy);
  else
    return Qnil;
}

void rxml_node_registerNode(xmlNodePtr node)
{
  node->_private = NULL;
}

void rxml_node_deregisterNode(xmlNodePtr xnode)
{
  VALUE node;

  if (xnode->_private == NULL)
    return;
  node = (VALUE) xnode->_private;
  DATA_PTR( node) = NULL;
}

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_xml_node(void)
{
  xmlRegisterNodeDefault(rxml_node_registerNode);
  xmlDeregisterNodeDefault(rxml_node_deregisterNode);

  cXMLNode = rb_define_class_under(mXML, "Node", rb_cObject);

  rb_define_const(cXMLNode, "SPACE_DEFAULT", INT2NUM(0));
  rb_define_const(cXMLNode, "SPACE_PRESERVE", INT2NUM(1));
  rb_define_const(cXMLNode, "SPACE_NOT_INHERIT", INT2NUM(-1));
  rb_define_const(cXMLNode, "XLINK_ACTUATE_AUTO", INT2NUM(1));
  rb_define_const(cXMLNode, "XLINK_ACTUATE_NONE", INT2NUM(0));
  rb_define_const(cXMLNode, "XLINK_ACTUATE_ONREQUEST", INT2NUM(2));
  rb_define_const(cXMLNode, "XLINK_SHOW_EMBED", INT2NUM(2));
  rb_define_const(cXMLNode, "XLINK_SHOW_NEW", INT2NUM(1));
  rb_define_const(cXMLNode, "XLINK_SHOW_NONE", INT2NUM(0));
  rb_define_const(cXMLNode, "XLINK_SHOW_REPLACE", INT2NUM(3));
  rb_define_const(cXMLNode, "XLINK_TYPE_EXTENDED", INT2NUM(2));
  rb_define_const(cXMLNode, "XLINK_TYPE_EXTENDED_SET", INT2NUM(3));
  rb_define_const(cXMLNode, "XLINK_TYPE_NONE", INT2NUM(0));
  rb_define_const(cXMLNode, "XLINK_TYPE_SIMPLE", INT2NUM(1));

  rb_define_const(cXMLNode, "ELEMENT_NODE", INT2FIX(XML_ELEMENT_NODE));
  rb_define_const(cXMLNode, "ATTRIBUTE_NODE", INT2FIX(XML_ATTRIBUTE_NODE));
  rb_define_const(cXMLNode, "TEXT_NODE", INT2FIX(XML_TEXT_NODE));
  rb_define_const(cXMLNode, "CDATA_SECTION_NODE", INT2FIX(XML_CDATA_SECTION_NODE));
  rb_define_const(cXMLNode, "ENTITY_REF_NODE", INT2FIX(XML_ENTITY_REF_NODE));
  rb_define_const(cXMLNode, "ENTITY_NODE", INT2FIX(XML_ENTITY_NODE));
  rb_define_const(cXMLNode, "PI_NODE", INT2FIX(XML_PI_NODE));
  rb_define_const(cXMLNode, "COMMENT_NODE", INT2FIX(XML_COMMENT_NODE));
  rb_define_const(cXMLNode, "DOCUMENT_NODE", INT2FIX(XML_DOCUMENT_NODE));
  rb_define_const(cXMLNode, "DOCUMENT_TYPE_NODE", INT2FIX(XML_DOCUMENT_TYPE_NODE));
  rb_define_const(cXMLNode, "DOCUMENT_FRAG_NODE", INT2FIX(XML_DOCUMENT_FRAG_NODE));
  rb_define_const(cXMLNode, "NOTATION_NODE", INT2FIX(XML_NOTATION_NODE));
  rb_define_const(cXMLNode, "HTML_DOCUMENT_NODE", INT2FIX(XML_HTML_DOCUMENT_NODE));
  rb_define_const(cXMLNode, "DTD_NODE", INT2FIX(XML_DTD_NODE));
  rb_define_const(cXMLNode, "ELEMENT_DECL", INT2FIX(XML_ELEMENT_DECL));
  rb_define_const(cXMLNode, "ATTRIBUTE_DECL", INT2FIX(XML_ATTRIBUTE_DECL));
  rb_define_const(cXMLNode, "ENTITY_DECL", INT2FIX(XML_ENTITY_DECL));
  rb_define_const(cXMLNode, "NAMESPACE_DECL", INT2FIX(XML_NAMESPACE_DECL));
  rb_define_const(cXMLNode, "XINCLUDE_START", INT2FIX(XML_XINCLUDE_START));
  rb_define_const(cXMLNode, "XINCLUDE_END", INT2FIX(XML_XINCLUDE_END));

#ifdef LIBXML_DOCB_ENABLED
  rb_define_const(cXMLNode, "DOCB_DOCUMENT_NODE", INT2FIX(XML_DOCB_DOCUMENT_NODE));
#else
  rb_define_const(cXMLNode, "DOCB_DOCUMENT_NODE", Qnil);
#endif

  rb_define_singleton_method(cXMLNode, "new_cdata", rxml_node_new_cdata, -1);
  rb_define_singleton_method(cXMLNode, "new_comment", rxml_node_new_comment, -1);
  rb_define_singleton_method(cXMLNode, "new_text", rxml_node_new_text, 1);

  /* Initialization */
  rb_define_alloc_func(cXMLNode, rxml_node_alloc);
  rb_define_method(cXMLNode, "initialize", rxml_node_initialize, -1);

  /* Traversal */
  rb_include_module(cXMLNode, rb_mEnumerable);
  rb_define_method(cXMLNode, "[]", rxml_node_attribute_get, 1);
  rb_define_method(cXMLNode, "each", rxml_node_each, 0);
  rb_define_method(cXMLNode, "first", rxml_node_first_get, 0);
  rb_define_method(cXMLNode, "last", rxml_node_last_get, 0);
  rb_define_method(cXMLNode, "next", rxml_node_next_get, 0);
  rb_define_method(cXMLNode, "parent", rxml_node_parent_get, 0);
  rb_define_method(cXMLNode, "prev", rxml_node_prev_get, 0);

  /* Modification */
  rb_define_method(cXMLNode, "<<", rxml_node_content_add, 1);
  rb_define_method(cXMLNode, "[]=", rxml_node_property_set, 2);
  rb_define_method(cXMLNode, "child_add", rxml_node_child_add, 1);
  rb_define_method(cXMLNode, "child=", rxml_node_child_set, 1);
  rb_define_method(cXMLNode, "sibling=", rxml_node_sibling_set, 1);
  rb_define_method(cXMLNode, "next=", rxml_node_next_set, 1);
  rb_define_method(cXMLNode, "prev=", rxml_node_prev_set, 1);

  /* Rest of the node api */
  rb_define_method(cXMLNode, "attributes", rxml_node_attributes_get, 0);
  rb_define_method(cXMLNode, "base", rxml_node_base_get, 0);
  rb_define_method(cXMLNode, "base=", rxml_node_base_set, 1);
  rb_define_method(cXMLNode, "blank?", rxml_node_empty_q, 0);
  rb_define_method(cXMLNode, "copy", rxml_node_copy, 1);
  rb_define_method(cXMLNode, "content", rxml_node_content_get, 0);
  rb_define_method(cXMLNode, "content=", rxml_node_content_set, 1);
  rb_define_method(cXMLNode, "content_stripped", rxml_node_content_stripped_get, 0);
  rb_define_method(cXMLNode, "debug", rxml_node_debug, 0);
  rb_define_method(cXMLNode, "doc", rxml_node_doc, 0);
  rb_define_method(cXMLNode, "empty?", rxml_node_empty_q, 0);
  rb_define_method(cXMLNode, "eql?", rxml_node_eql_q, 1);
  rb_define_method(cXMLNode, "lang", rxml_node_lang_get, 0);
  rb_define_method(cXMLNode, "lang=", rxml_node_lang_set, 1);
  rb_define_method(cXMLNode, "line_num", rxml_node_line_num, 0);
  rb_define_method(cXMLNode, "name", rxml_node_name_get, 0);
  rb_define_method(cXMLNode, "name=", rxml_node_name_set, 1);
  rb_define_method(cXMLNode, "node_type", rxml_node_type, 0);
  rb_define_method(cXMLNode, "path", rxml_node_path, 0);
  rb_define_method(cXMLNode, "pointer", rxml_node_pointer, 1);
  rb_define_method(cXMLNode, "remove!", rxml_node_remove_ex, 0);
  rb_define_method(cXMLNode, "space_preserve", rxml_node_space_preserve_get, 0);
  rb_define_method(cXMLNode, "space_preserve=", rxml_node_space_preserve_set, 1);
  rb_define_method(cXMLNode, "to_s", rxml_node_to_s, -1);
  rb_define_method(cXMLNode, "xlink?", rxml_node_xlink_q, 0);
  rb_define_method(cXMLNode, "xlink_type", rxml_node_xlink_type, 0);
  rb_define_method(cXMLNode, "xlink_type_name", rxml_node_xlink_type_name, 0);

  rb_define_alias(cXMLNode, "==", "eql?");
}
