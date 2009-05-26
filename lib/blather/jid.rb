module Blather

  ##
  # This is a simple modification of the JID class from XMPP4R
  class JID
    include Comparable

    PATTERN = /^(?:([^@]*)@)??([^@\/]*)(?:\/(.*?))?$/.freeze

    ##
    # Get the JID's node
    attr_reader :node

    ##
    # Get the JID's domain
    attr_reader :domain

    ##
    # Get the JID's resource
    attr_reader :resource

    ##
    # If a JID is passed in just return it. 
    # No need to copy out all the values
    def self.new(node, domain = nil, resource = nil)
      node.is_a?(JID) ? node : super
    end

    ##
    # Create a new JID. If called as new('a@b/c'), parse the string and
    # split (node, domain, resource)
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
    # return:: [JID]
    def stripped
      self.class.new @node, @domain
    end

    ##
    # Removes the resource (sets it to nil)
    # return:: [JID] self
    def strip!
      @resource = nil
      self
    end

    ##
    # Compare two JIDs,
    # helpful for sorting etc.
    #
    # String representations are compared, see JID#to_s
    def <=>(o)
      to_s <=> o.to_s
    end
    alias_method :eql?, :==

    ##
    # Test if JID is stripped
    def stripped?
      @resource.nil?
    end
  end

end
