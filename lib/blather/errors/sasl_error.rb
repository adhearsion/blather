module Blather

class SASLError < BlatherError
  class_inheritable_accessor :err_name
  @@registrations = {}

  register :sasl_error

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
  # Factory to create the proper error object from an error node
  def self.import(node)
    err_name = node.children.first.element_name
    class_from_registration(err_name).new
  end

  ##
  # XMPP defined error name
  def err_name
    self.class.err_name
  end

  ##
  # The receiving entity acknowledges an <abort/> element sent by the initiating entity; sent in reply to the <abort/> element.
  class Aborted < SASLError
    register :sasl_aborted_error, 'aborted'
  end

  ##
  # The data provided by the initiating entity could not be processed because the [BASE64] encoding is incorrect
  # (e.g., because the encoding does not adhere to the definition in Section 3 of [BASE64]); sent in reply to a <response/>
  # element or an <auth/> element with initial response data.
  class IncorrectEncoding < SASLError
    register :sasl_incorrect_encoding_error, 'incorrect-encoding'
  end
  
  ##
  # The authzid provided by the initiating entity is invalid, either because it is incorrectly formatted or because the
  # initiating entity does not have permissions to authorize that ID; sent in reply to a <response/> element or an <auth/>
  # element with initial response data.
  class InvalidAuthzid < SASLError
    register :sasl_invalid_authzid_error, 'invalid-authzid'
  end
  
  ##
  # The initiating entity did not provide a mechanism or requested a mechanism that is not supported by the receiving entity;
  # sent in reply to an <auth/> element.
  class InvalidMechanism < SASLError
    register :sasl_invalid_mechanism_error, 'invalid-mechanism'
  end
  
  ##
  # The mechanism requested by the initiating entity is weaker than server policy permits for that initiating entity; sent in
  # reply to a <response/> element or an <auth/> element with initial response data.
  class MechanismTooWeak < SASLError
    register :sasl_mechanism_too_weak_error, 'mechanism-too-weak'
  end
  
  ##
  # The authentication failed because the initiating entity did not provide valid credentials (this includes but is not limited
  # to the case of an unknown username); sent in reply to a <response/> element or an <auth/> element with initial response data.
  class NotAuthorized < SASLError
    register :sasl_not_authorized_error, 'not-authorized'
  end
  
  ##
  # The authentication failed because of a temporary error condition within the receiving entity; sent in reply to an <auth/>
  # element or <response/> element.
  class TemporaryAuthFailure < SASLError
    register :sasl_temporary_auth_failure_error, 'temporary-auth-failure'
  end
end #SASLError

end #Blather
