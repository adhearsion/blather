module Blather

##
# Stream Errors
# RFC3920 Section 9.3 (http://xmpp.org/rfcs/rfc3920.html#streams-error-rules)
class StreamError < BlatherError
  class_inheritable_accessor :err_name
  @@registrations = {}

  register :stream_error

  attr_reader :text, :extras

  ##
  # Register the handler and type to simplify importing
  def self.register(handler, err_name)
    super handler
    self.err_name = err_name
    @@registrations[err_name] = self
  end

  ##
  # Retreive an error class from a given name
  def self.class_from_registration(err_name)
    @@registrations[err_name.to_s] || self
  end

  ##
  # Factory method for instantiating the proper class
  # for the error
  def self.import(node)
    name = node.find_first('descendant::*[name()!="text"]', 'urn:ietf:params:xml:ns:xmpp-streams').element_name
    text = node.find_first 'descendant::text', 'urn:ietf:params:xml:ns:xmpp-streams'
    text = text.content if text

    extras = node.find("descendant::*[name()!='text' and name()!='#{name}']").map { |n| n }

    class_from_registration(name).new text, extras
  end

  ##
  # <tt>text</tt> is the (optional) error message.
  # <tt>extras</tt> should be an array of nodes to attach to the error
  # each extra should be in an application specific namespace
  # see RFC3920 Section 4.7.2 (http://xmpp.org/rfcs/rfc3920.html#rfc.section.4.7.2)
  def initialize(text = nil, extras = [])
    @text = text
    @extras = extras
  end

  ##
  # XMPP defined error name
  def err_name
    self.class.err_name
  end

  ##
  # Creates an XML node from the error
  def to_node
    node = XMPPNode.new('stream:error')

    err = XMPPNode.new(self.err_name)
    err.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
    node << err

    if self.text
      text = XMPPNode.new('text')
      text.namespace = 'urn:ietf:params:xml:ns:xmpp-streams'
      text << self.text
      node << text
    end

    self.extras.each do |extra|
      extra_copy = extra.copy
      extra_copy.namespace = extra.namespace
      node << extra_copy
    end
    node
  end

  ##
  # Turns the object into XML fit to be sent over the stream
  def to_xml
    to_node.to_s
  end

  def inspect # :nodoc:
    "Stream Error (#{self.err_name}): #{self.text}"
  end
  alias_method :to_s, :inspect # :nodoc:

  ##
  # Something bad happened while parsing the incoming stream
  class ParseError < BlatherError
    register :parse_error
  end

  ##
  # The entity has sent XML that cannot be processed; this error MAY be used instead of the more specific XML-related errors,
  # such as <bad-namespace-prefix/>, <invalid-xml/>, <restricted-xml/>, <unsupported-encoding/>, and <xml-not-well-formed/>,
  # although the more specific errors are preferred.
  class BadFormat < StreamError
    register :stream_bad_format_error, 'bad-format'
  end

  ##
  # The entity has sent a namespace prefix that is unsupported, or has sent no namespace prefix on an element that requires
  # such a prefix (see XML Namespace Names and Prefixes).
  class BadNamespacePrefix < StreamError
    register :stream_bad_namespace_prefix_error, 'bad-namespace-prefix'
  end
  
  ##
  # The server is closing the active stream for this entity because a new stream has been initiated that conflicts with the
  # existing stream.
  class Conflict < StreamError
    register :stream_conflict_error, 'conflict'
  end
  
  ##
  # The entity has not generated any traffic over the stream for some period of time (configurable according to a local service policy).
  class ConnectionTimeout < StreamError
    register :stream_connection_timeout_error, 'connection-timeout'
  end
  
  ##
  # The value of the 'to' attribute provided by the initiating entity in the stream header corresponds to a hostname that is no
  # longer hosted by the server.
  class HostGone < StreamError
    register :stream_host_gone_error, 'host-gone'
  end
  
  ##
  # The value of the 'to' attribute provided by the initiating entity in the stream header does not correspond to a hostname that
  # is hosted by the server.
  class HostUnknown < StreamError
    register :stream_host_unknown_error, 'host-unknown'
  end
  
  ##
  # a stanza sent between two servers lacks a 'to' or 'from' attribute (or the attribute has no value).
  class ImproperAddressing < StreamError
    register :stream_improper_addressing_error, 'improper-addressing'
  end
  
  ##
  # The server has experienced a misconfiguration or an otherwise-undefined internal error that prevents it from servicing the stream.
  class InternalServerError < StreamError
    register :stream_internal_server_error, 'internal-server-error'
  end
  
  ##
  # The JID or hostname provided in a 'from' address does not match an authorized JID or validated domain negotiated between
  # servers via SASL or dialback, or between a client and a server via authentication and resource binding.
  class InvalidFrom < StreamError
    register :stream_invalid_from_error, 'invalid-from'
  end
  
  ##
  # The stream ID or dialback ID is invalid or does not match an ID previously provided.
  class InvalidId < StreamError
    register :stream_invalid_id_error, 'invalid-id'
  end
  
  ##
  # The streams namespace name is something other than "http://etherx.jabber.org/streams" or the dialback namespace name is something
  # other than "jabber:server:dialback" (see XML Namespace Names and Prefixes).
  class InvalidNamespace < StreamError
    register :stream_invalid_namespace_error, 'invalid-namespace'
  end
  
  ##
  # The entity has sent invalid XML over the stream to a server that performs validation (see Validation).
  class InvalidXml < StreamError
    register :stream_invalid_xml_error, 'invalid-xml'
  end
  
  ##
  # The entity has attempted to send data before the stream has been authenticated, or otherwise is not authorized to perform an action
  # related to stream negotiation; the receiving entity MUST NOT process the offending stanza before sending the stream error.
  class NotAuthorized < StreamError
    register :stream_not_authorized_error, 'not-authorized'
  end
  
  ##
  # The entity has violated some local service policy; the server MAY choose to specify the policy in the <text/> element or an
  # application-specific condition element.
  class PolicyViolation < StreamError
    register :stream_policy_violation_error, 'policy-violation'
  end
  
  ##
  # The server is unable to properly connect to a remote entity that is required for authentication or authorization.
  class RemoteConnectionFailed < StreamError
    register :stream_remote_connection_failed_error, 'remote-connection-failed'
  end
  
  ##
  # The server lacks the system resources necessary to service the stream.
  class ResourceConstraint < StreamError
    register :stream_resource_constraint_error, 'resource-constraint'
  end
  
  ##
  # The entity has attempted to send restricted XML features such as a comment, processing instruction, DTD, entity reference,
  # or unescaped character (see Restrictions).
  class RestrictedXml < StreamError
    register :stream_restricted_xml_error, 'restricted-xml'
  end
  
  ##
  # The server will not provide service to the initiating entity but is redirecting traffic to another host; the server SHOULD
  # specify the alternate hostname or IP address (which MUST be a valid domain identifier) as the XML character data of the
  # <see-other-host/> element.
  class SeeOtherHost < StreamError
    register :stream_see_other_host_error, 'see-other-host'
  end
  
  ##
  # The server is being shut down and all active streams are being closed.
  class SystemShutdown < StreamError
    register :stream_system_shutdown_error, 'system-shutdown'
  end
  
  ##
  # The error condition is not one of those defined by the other conditions in this list; this error condition SHOULD be used
  # only in conjunction with an application-specific condition.
  class UndefinedCondition < StreamError
    register :stream_undefined_condition_error, 'undefined-condition'
  end
  
  ##
  # The initiating entity has encoded the stream in an encoding that is not supported by the server (see Character Encoding).
  class UnsupportedEncoding < StreamError
    register :stream_unsupported_encoding_error, 'unsupported-encoding'
  end
  
  ##
  # The initiating entity has sent a first-level child of the stream that is not supported by the server.
  class UnsupportedStanzaType < StreamError
    register :stream_unsupported_stanza_type_error, 'unsupported-stanza-type'
  end
  
  ##
  # The value of the 'version' attribute provided by the initiating entity in the stream header specifies a version of XMPP
  # That is not supported by the server; the server MAY specify the version(s) it supports in the <text/> element.
  class UnsupportedVersion < StreamError
    register :stream_unsupported_version_error, 'unsupported-version'
  end
  
  ##
  # The initiating entity has sent XML that is not well-formed as defined by [XML].
  class XmlNotWellFormed < StreamError
    register :stream_xml_not_well_formed_error, 'xml-not-well-formed'
  end

end #StreamError

end #Blather
