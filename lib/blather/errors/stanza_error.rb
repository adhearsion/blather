module Blather

##
# Stanza errors
# RFC3920 Section 9.3 (http://xmpp.org/rfcs/rfc3920.html#stanzas-error)
class StanzaError < BlatherError
  VALID_TYPES = [:cancel, :continue, :modify, :auth, :wait]

  class_inheritable_accessor :err_name
  @@registrations = {}
  
  register :stanza_error

  attr_reader :original, :type, :text, :extras

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
    original = node.copy
    original.remove_child 'error'

    error_node = node.find_first '//*[local-name()="error"]'

    name = error_node.find_first('child::*[name()!="text"]', 'urn:ietf:params:xml:ns:xmpp-stanzas').element_name
    type = error_node['type']
    text = node.find_first '//err_ns:text', :err_ns => 'urn:ietf:params:xml:ns:xmpp-stanzas'
    text = text.content if text

    extras = error_node.find("descendant::*[name()!='text' and name()!='#{name}']").map { |n| n }

    class_from_registration(name).new original, type, text, extras
  end

  ##
  # <tt>original</tt> An original node must be provided for stanza errors. You can't declare
  # a stanza error on without a stanza.
  # <tt>type</tt> is the error type specified in RFC3920 (http://xmpp.org/rfcs/rfc3920.html#rfc.section.9.3.2)
  # <tt>text</tt> is an option error description
  # <tt>extras</tt> an array of application specific nodes to add to the error. These should be properly namespaced.
  def initialize(original, type, text = nil, extras = [])
    @original = original
    self.type = type
    @text = text
    @extras = extras
  end

  ##
  # XMPP defined error name
  def err_name
    self.class.err_name
  end

  ##
  # Set the error type (see RFC3920 Section 9.3.2 (http://xmpp.org/rfcs/rfc3920.html#rfc.section.9.3.2))
  def type=(type)
    type = type.to_sym
    raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}" if !VALID_TYPES.include?(type)
    @type = type
  end

  ##
  # Creates an XML node from the error
  def to_node
    node = self.original.reply

    error_node = XMPPNode.new 'error'
    err = XMPPNode.new(self.err_name)
    err.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
    error_node << err

    if self.text
      text = XMPPNode.new('text')
      text.namespace = 'urn:ietf:params:xml:ns:xmpp-stanzas'
      text << self.text
      error_node << text
    end

    self.extras.each do |extra|
      extra_copy = extra.copy
      extra_copy.namespace = extra.namespace
      error_node << extra_copy
    end

    node << error_node
    node.type = 'error'
    node
  end

  ##
  # Turns the object into XML fit to be sent over the stream
  def to_xml
    to_node.to_s
  end

  def inspect # :nodoc:
    "Stanza Error (#{self.err_name}): #{self.text}"
  end
  alias_method :to_s, :inspect # :nodoc:

  ##
  # The sender has sent XML that is malformed or that cannot be processed (e.g., an IQ stanza that includes
  # an unrecognized value of the 'type' attribute); the associated error type SHOULD be "modify"
  class BadRequest < StanzaError
    register :stanza_bad_request_error, 'bad-request'
  end

  ##
  # Access cannot be granted because an existing resource or session exists with the same name or address;
  # the associated error type SHOULD be "cancel"
  class Conflict < StanzaError
    register :stanza_conflict_error, 'conflict'
  end

  ##
  # the feature requested is not implemented by the recipient or server and therefore cannot be processed;
  # the associated error type SHOULD be "cancel".
  class FeatureNotImplemented < StanzaError
    register :stanza_feature_not_implemented_error, 'feature-not-implemented'
  end

  ##
  # the requesting entity does not possess the required permissions to perform the action;
  # the associated error type SHOULD be "auth".
  class Forbidden < StanzaError
    register :stanza_forbidden_error, 'forbidden'
  end

  ##
  # the recipient or server can no longer be contacted at this address (the error stanza MAY contain a new address
  # in the XML character data of the <gone/> element); the associated error type SHOULD be "modify".
  class Gone < StanzaError
    register :stanza_gone_error, 'gone'
  end

  ##
  # the server could not process the stanza because of a misconfiguration or an otherwise-undefined internal server error;
  # the associated error type SHOULD be "wait".
  class InternalServerError < StanzaError
    register :stanza_internal_server_error, 'internal-server-error'
  end

  ##
  # the addressed JID or item requested cannot be found; the associated error type SHOULD be "cancel".
  class ItemNotFound < StanzaError
    register :stanza_item_not_found_error, 'item-not-found'
  end

  ##
  # the addressed JID or item requested cannot be found; the associated error type SHOULD be "cancel".
  class JidMalformed < StanzaError
    register :stanza_jid_malformed_error, 'jid-malformed'
  end

  ##
  # the recipient or server understands the request but is refusing to process it because it does not meet criteria defined
  # by the recipient or server (e.g., a local policy regarding acceptable words in messages); the associated error type SHOULD be "modify".
  class NotAcceptable < StanzaError
    register :stanza_not_acceptable_error, 'not-acceptable'
  end

  ##
  # The recipient or server does not allow any entity to perform the action; the associated error type SHOULD be "cancel".
  class NotAllowed < StanzaError
    register :stanza_not_allowed_error, 'not-allowed'
  end

  ##
  # the sender must provide proper credentials before being allowed to perform the action, or has provided improper credentials;
  # the associated error type SHOULD be "auth".
  class NotAuthorized < StanzaError
    register :stanza_not_authorized_error, 'not-authorized'
  end

  ##
  # the requesting entity is not authorized to access the requested service because payment is required; the associated error type SHOULD be "auth".
  class PaymentRequired < StanzaError
    register :stanza_payment_required_error, 'payment-required'
  end

  ##
  # the intended recipient is temporarily unavailable; the associated error type SHOULD be "wait" (note: an application MUST NOT
  # return this error if doing so would provide information about the intended recipient's network availability to an entity that
  # is not authorized to know such information).
  class RecipientUnavailable < StanzaError
    register :stanza_recipient_unavailable_error, 'recipient-unavailable'
  end

  ##
  # the recipient or server is redirecting requests for this information to another entity, usually temporarily (the error stanza SHOULD contain
  # the alternate address, which MUST be a valid JID, in the XML character data of the <redirect/> element); the associated error type SHOULD be "modify".
  class Redirect < StanzaError
    register :stanza_redirect_error, 'redirect'
  end

  ##
  # the requesting entity is not authorized to access the requested service because registration is required; the associated error type SHOULD be "auth".
  class RegistrationRequired < StanzaError
    register :stanza_registration_required_error, 'registration-required'
  end

  ##
  # a remote server or service specified as part or all of the JID of the intended recipient does not exist; the associated error type SHOULD be "cancel".
  class RemoteServerNotFound < StanzaError
    register :stanza_remote_server_not_found_error, 'remote-server-not-found'
  end

  ##
  # a remote server or service specified as part or all of the JID of the intended recipient (or required to fulfill a request) could not be
  # contacted within a reasonable amount of time; the associated error type SHOULD be "wait".
  class RemoteServerTimeout < StanzaError
    register :stanza_remote_server_timeout_error, 'remote-server-timeout'
  end

  ##
  # the server or recipient lacks the system resources necessary to service the request; the associated error type SHOULD be "wait".
  class ResourceConstraint < StanzaError
    register :stanza_resource_constraint_error, 'resource-constraint'
  end

  ##
  # the server or recipient does not currently provide the requested service; the associated error type SHOULD be "cancel".
  class ServiceUnavailable < StanzaError
    register :stanza_service_unavailable_error, 'service-unavailable'
  end

  ##
  # the requesting entity is not authorized to access the requested service because a subscription is required; the associated error type SHOULD be "auth".
  class SubscriptionRequired < StanzaError
    register :stanza_subscription_required_error, 'subscription-required'
  end

  ##
  # the error condition is not one of those defined by the other conditions in this list; any error type may be associated with this condition,
  # and it SHOULD be used only in conjunction with an application-specific condition.
  class UndefinedCondition < StanzaError
    register :stanza_undefined_condition_error, 'undefined-condition'
  end

  ##
  # the recipient or server understood the request but was not expecting it at this time (e.g., the request was out of order);
  # the associated error type SHOULD be "wait".
  class UnexpectedRequest < StanzaError
    register :stanza_unexpected_request_error, 'unexpected-request'
  end
end #StanzaError

end #Blather