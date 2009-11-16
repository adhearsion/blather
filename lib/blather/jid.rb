module Blather

  # This is a simple modification of the JID class from XMPP4R
  class JID
    include Comparable

    # @private
    PATTERN = /^(?:([^@]*)@)??([^@\/]*)(?:\/(.*?))?$/.freeze

    attr_reader :node,
                :domain,
                :resource

    def self.new(node, domain = nil, resource = nil)
      node.is_a?(JID) ? node : super
    end

    # Create a new JID object
    #
    # @overload initialize(jid)
    #   Passes the jid object right back out
    #   @param [Blather::JID] jid a jid object
    # @overload initialize(jid)
    #   Creates a new JID parsed out of the provided jid
    #   @param [String] jid a jid in the standard format ("node@domain/resource")
    # @overload initialize(node, domain = nil, resource = nil)
    #   Creates a new JID
    #   @param [String] node the node of the JID
    #   @param [String, nil] domian the domain of the JID
    #   @param [String, nil] resource the resource of the JID
    # @raise [ArgumentError] if the parts of the JID are too large (1023 bytes)
    # @return [Blather::JID] a new jid object
    def initialize(node, domain = nil, resource = nil)
      @resource = resource
      @domain = domain
      @node = node

      if @domain.nil? && @resource.nil?
        @node, @domain, @resource = @node.to_s.scan(PATTERN).first
      end

      @node.downcase!   if @node
      @domain.downcase! if @domain

      raise ArgumentError, 'Node too long'      if (@node || '').length > 1023
      raise ArgumentError, 'Domain too long'    if (@domain || '').length > 1023
      raise ArgumentError, 'Resource too long'  if (@resource || '').length > 1023
    end

    # Turn the JID into a string
    #
    # @return [String] the JID as a string:
    #   ""
    #   "domain"
    #   "node@domain"
    #   "domain/resource"
    #   "node@domain/resource"
    def to_s
      s = @domain
      s = "#{@node}@#{s}" if @node
      s = "#{s}/#{@resource}" if @resource
      s
    end

    # Returns a new JID with resource removed.
    #
    # @return [Blather::JID] a new JID without a resource
    def stripped
      dup.strip!
    end

    # Removes the resource (sets it to nil)
    #
    # @return [Blather::JID] the JID without a resource
    def strip!
      @resource = nil
      self
    end

    # Compare two JIDs, helpful for sorting etc.
    #
    # String representations are compared, see JID#to_s
    #
    # @param [#to_s] other a JID to comare against
    # @return [Fixnum<-1, 0, 1>]
    def <=>(other)
      to_s <=> other.to_s
    end
    alias_method :eql?, :==

    # Test if JID is stripped
    #
    # @return [true, false]
    def stripped?
      @resource.nil?
    end
  end

end
