module Blather
class Stanza
class Iq
  # # SOCKS5 Bytestreams Stanza
  #
  # [XEP-0065: SOCKS5 Bytestreams](http://xmpp.org/extensions/xep-0065.html)
  #
  # @handler :s5b_open
  class S5b < Query
    # @private
    NS_S5B = 'http://jabber.org/protocol/bytestreams'

    register :s5b_open, :query, NS_S5B

    # Overrides the parent method to remove query node
    #
    # @see Blather::Stanza#reply
    def reply
      reply = super
      reply.remove_children :query
      reply
    end

    # Get the sid of the file transfer
    #
    # @return [String]
    def sid
      query['sid']
    end

    # Get the used streamhost
    #
    # @return [S5b::StreamHostUsed]
    def streamhost_used
      StreamHostUsed.new query.find_first('.//ns:streamhost-used', :ns => self.class.registered_ns)
    end

    # Set the used streamhost
    #
    # @param [Blather::JID, String, nil] jid the jid of the used streamhost
    def streamhost_used=(jid)
      query.find('.//ns:streamhost-used', :ns => self.class.registered_ns).remove

      if jid
        query << StreamHostUsed.new(jid)
      end
    end

    # Get the streamhosts
    #
    # @return [Array<S5b::StreamHost>]
    def streamhosts
      query.find('.//ns:streamhost', :ns => self.class.registered_ns).map do |s|
        StreamHost.new s
      end
    end

    # Set the streamhosts
    #
    # @param streamhosts the array of streamhosts, passed directly to StreamHost.new
    def streamhosts=(streamhosts)
      query.find('.//ns:streamhost', :ns => self.class.registered_ns).remove
      if streamhosts
        [streamhosts].flatten.each { |s| self.query << StreamHost.new(s) }
      end
    end

    # StreamHost Stanza
    class StreamHost < XMPPNode
      register 'streamhost', NS_S5B

      # Create a new S5b::StreamHost
      #
      # @overload new(node)
      #   Create a new StreamHost by inheriting an existing node
      #   @param [XML::Node] node an XML::Node to inherit from
      # @overload new(opts)
      #   Create a new StreamHost through a hash of options
      #   @param [Hash] opts a hash options
      #   @option opts [Blather::JID, String] :jid the JID of the StreamHost
      #   @option opts [#to_s] :host the host the StreamHost
      #   @option opts [#to_s] :port the post of the StreamHost
      # @overload new(jid, host = nil, port = nil)
      #   Create a new StreamHost
      #   @param [Blather::JID, String] jid the JID of the StreamHost
      #   @param [#to_s] host the host the StreamHost
      #   @param [#to_s] port the post of the StreamHost
      def self.new(jid, host = nil, port = nil)
        new_node = super 'streamhost'

        case jid
        when Nokogiri::XML::Node
          new_node.inherit jid
        when Hash
          new_node.jid = jid[:jid]
          new_node.host = jid[:host]
          new_node.port = jid[:port]
        else
          new_node.jid = jid
          new_node.host = host
          new_node.port = port
        end
        new_node
      end

      # Get the jid of the streamhost
      #
      # @return [Blather::JID, nil]
      def jid
        if j = read_attr(:jid)
          JID.new(j)
        else
          nil
        end
      end

      # Set the jid of the streamhost
      #
      # @param [Blather::JID, String, nil]
      def jid=(j)
        write_attr :jid, (j ? j.to_s : nil)
      end

      # Get the host address of the streamhost
      #
      # @return [String, nil]
      def host
        read_attr :host
      end

      # Set the host address of the streamhost
      #
      # @param [String, nil]
      def host=(h)
        write_attr :host, h
      end

      # Get the port of the streamhost
      #
      # @return [Fixnum, nil]
      def port
        if p = read_attr(:port)
          p.to_i
        else
          nil
        end
      end

      # Set the port of the streamhost
      #
      # @param [String, Fixnum, nil]
      def port=(p)
        write_attr :port, p
      end
    end

    # Stream host used stanza
    class StreamHostUsed < XMPPNode
      register 'streamhost-used', NS_S5B

      # Create a new S5b::StreamHostUsed
      #
      # @overload new(node)
      #   Create a new StreamHostUsed by inheriting an existing node
      #   @param [XML::Node] node an XML::Node to inherit from
      # @overload new(opts)
      #   Create a new StreamHostUsed through a hash of options
      #   @param [Hash] opts a hash options
      #   @option opts [Blather::JID, String] :jid the JID of the StreamHostUsed
      # @overload new(jid)
      #   Create a new StreamHostUsed
      #   @param [Blather::JID, String] jid the JID of the StreamHostUsed
      def self.new(jid)
        new_node = super 'streamhost-used'

        case jid
        when Nokogiri::XML::Node
          new_node.inherit jid
        when Hash
          new_node.jid = jid[:jid]
        else
          new_node.jid = jid
        end
        new_node
      end

      # Get the jid of the used streamhost
      #
      # @return [Blather::JID, nil]
      def jid
        if j = read_attr(:jid)
          JID.new(j)
        else
          nil
        end
      end

      # Set the jid of the used streamhost
      #
      # @param [Blather::JID, String, nil]
      def jid=(j)
        write_attr :jid, (j ? j.to_s : nil)
      end
    end
  end
end
end
end
