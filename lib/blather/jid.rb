module Blather

  ##
  # This is a simple modification of the JID class from XMPP4R
  class JID
    include Comparable

    PATTERN = /^(?:([^@]*)@)??([^@\/]*)(?:\/(.*?))?$/.freeze

    attr_reader :node,
                :domain,
                :resource

    ##
    # Create a new JID. If called as new('a@b/c'), parse the string and split (node, domain, resource).
    # * +node+ - can be any of the following:
    #   * a string representing the JID ("node@domain.tld/resource")
    #   * a JID. in which case nothing will be done and the original JID will be passed back
    #   * a string representing the node
    # * +domain+ - the domain of the JID
    # * +resource+ - the resource the connection should be bound to
    def self.new(node, domain = nil, resource = nil)
      node.is_a?(JID) ? node : super
    end

    def initialize(node, domain = nil, resource = nil) # :nodoc:
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

    ##
    # Returns a string representation of the JID
    # * ""
    # * "domain"
    # * "node@domain"
    # * "domain/resource"
    # * "node@domain/resource"
    def to_s
      s = @domain
      s = "#{@node}@#{s}" if @node
      s = "#{s}/#{@resource}" if @resource
      s
    end

    ##
    # Returns a new JID with resource removed.
    def stripped
      dup.strip!
    end

    ##
    # Removes the resource (sets it to nil)
    def strip!
      @resource = nil
      self
    end

    ##
    # Compare two JIDs,
    # helpful for sorting etc.
    #
    # String representations are compared, see JID#to_s
    def <=>(other)
      to_s <=> other.to_s
    end
    alias_method :eql?, :==

    ##
    # Test if JID is stripped
    def stripped?
      @resource.nil?
    end
  end

end
