require 'time' # For Time#xmlschema

module Blather
class Stanza
class Iq

  # # Si Stanza
  #
  # [XEP-0096: SI File Transfer](http://xmpp.org/extensions/xep-0096.html)
  #
  # This is a base class for any si based Iq stanzas. It provides a base set
  # of methods for working with si stanzas
  #
  # @example Basic file transfer acceptance
  #     client.register_handler :file_transfer do |iq|
  #       transfer = Blather::FileTransfer.new(client, iq)
  #       transfer.accept(Blather::FileTransfer::SimpleFileReceiver, "/path/to/#{iq.si.file["name"]}", iq.si.file["size"].to_i)
  #     end
  #
  # @example Basic file transfer refusal
  #     client.register_handler :file_transfer do |iq|
  #       transfer = Blather::FileTransfer.new(client, iq)
  #       transfer.decline
  #     end
  #
  # @example File transfer acceptance by in-band bytestreams with custom handler
  #     client.register_handler :file_transfer do |iq|
  #       transfer = Blather::FileTransfer.new(client, iq)
  #       transfer.allow_ibb = true
  #       transfer.allow_s5b = false
  #       transfer.accept(MyFileReceiver, iq)
  #     end
  #
  # @handler :file_transfer
  class Si < Iq
    # @private
    NS_SI = 'http://jabber.org/protocol/si'
    register :file_transfer, :si, NS_SI

    # Overrides the parent method to ensure a si node is created
    #
    # @see Blather::Stanza::Iq.new
    def self.new(type = :set)
      node = super
      node.si
      node
    end

    # Overrides the parent method to ensure the current si node is destroyed
    #
    # @see Blather::Stanza::Iq#inherit
    def inherit(node)
      si.remove
      super
    end

    # Find or create si node
    #
    # @return [Si::Si]
    def si
      Si.find_or_create self
    end

    # Replaces si node
    #
    # @param [Si::Si, XML::Node] node the stanza's new si node
    #
    # @return [Si::Si]
    def si=(node)
      si.remove
      self << node
      Si.find_or_create self
    end

    # Overrides the parent method to ensure the current si node is destroyed
    #
    # @see Blather::Stanza#reply
    def reply
      reply = Stanza::Iq::Si.import super
      reply.si.remove
      reply
    end

    # Si stanza fragment
    class Si < XMPPNode
      # Create a new Si::Si object
      #
      # @param [XML::Node, nil] node a node to inherit from
      #
      # @return [Si::Si]
      def self.new(node = nil)
        new_node = super :si
        new_node.namespace = NS_SI
        new_node.inherit node if node
        new_node
      end

      # Find or create si node in Si Iq and converts it to Si::Si
      #
      # @param [Si] parent a Si Iq where to find or create si
      #
      # @return [Si::Si]
      def self.find_or_create(parent)
        if found_si = parent.at_xpath('//ns:si', :ns => NS_SI)
          si = self.new found_si
          found_si.remove
        else
          si = self.new
        end
        parent << si

        si
      end

      # Get the id of the stream
      #
      # @return [String, nil]
      def id
        read_attr :id
      end

      # Set the id
      #
      # @param [String, nil] id the id of the stream
      def id=(id)
        write_attr :id, id
      end

      # Get the MIME type of the stream
      #
      # @return [String, nil]
      def mime_type
        read_attr 'mime-type'
      end

      # Set the MIME type
      #
      # @param [String, nil] type the MIME type of the stream
      def mime_type=(type)
        write_attr 'mime-type', type
      end

      # Get the profile of the stream
      #
      # @return [String, nil]
      def profile
        read_attr :profile
      end

      # Set the profile
      #
      # @param [String, nil] profile the profile of the stream
      def profile=(profile)
        write_attr :profile, profile
      end

      # Find or create file node
      #
      # @return [Si::Si::File]
      def file
        File.find_or_create self
      end

      # Find or create feature node
      #
      # @return [Si::Si::Feature]
      def feature
        Feature.find_or_create self
      end

      # Feature stanza fragment
      class Feature < XMPPNode
        register :feature, 'http://jabber.org/protocol/feature-neg'

        # Create a new Si::Si::Feature object
        #
        # @param [XML::Node, nil] node a node to inherit from
        #
        # @return [Si::Si::Feature]
        def self.new(node = nil)
          new_node = super :feature
          new_node.namespace = self.registered_ns
          new_node.inherit node if node
          new_node
        end

        # Find or create feature node in si node and converts it to Si::Si::Feature
        #
        # @param [Si::Si] parent a si node where to find or create feature
        #
        # @return [Si::Si::Feature]
        def self.find_or_create(parent)
          if found_feature = parent.at_xpath('//ns:feature', :ns => self.registered_ns)
            feature = self.new found_feature
            found_feature.remove
          else
            feature = self.new
          end
          parent << feature

          feature
        end

        # Find or create x node
        #
        # @return [Stanza::X]
        def x
          Stanza::X.find_or_create self
        end
      end

      # File stanza fragment
      class File < XMPPNode
        register :file, 'http://jabber.org/protocol/si/profile/file-transfer'

        # Create a new Si::Si::File object
        #
        # @param [XML::Node, nil] node a node to inherit from
        #
        # @return [Si::Si::File]
        def self.new(name = nil, size = nil)
          new_node = super :file

          case name
          when Nokogiri::XML::Node
            new_node.inherit name
          else
            new_node.name = name
            new_node.size = size
          end
          new_node
        end

        # Find or create file node in si node and converts it to Si::Si::File
        #
        # @param [Si::Si] parent a si node where to find or create file
        #
        # @return [Si::Si::File]
        def self.find_or_create(parent)
          if found_file = parent.at_xpath('//ns:file', :ns => self.registered_ns)
            file = self.new found_file
            found_file.remove
          else
            file = self.new
          end
          parent << file

          file
        end

        # Get the filename
        #
        # @return [String, nil]
        def name
          read_attr :name
        end

        # Set the filename
        #
        # @param [String, nil] name the name of the file
        def name=(name)
          write_attr :name, name
        end

        # Get the hash
        #
        # @return [String, nil]
        def hash
          read_attr :hash
        end

        # Set the hash
        #
        # @param [String, nil] hash the MD5 hash of the file
        def hash=(hash)
          write_attr :hash, hash
        end

        # Get the date
        #
        # @return [Time, nil]
        def date
          begin
            Time.xmlschema(read_attr(:date))
          rescue ArgumentError
            nil
          end
        end

        # Set the date
        #
        # @param [Time, nil] date the last modification time of the file
        def date=(date)
          write_attr :date, (date ? date.xmlschema : nil)
        end

        # Get the size
        #
        # @return [Fixnum, nil]
        def size
          if (s = read_attr(:size)) && (s =~ /^\d+$/)
            s.to_i
          else
            nil
          end
        end

        # Set the size
        #
        # @param [Fixnum, nil] size the size, in bytes, of the file
        def size=(size)
          write_attr :size, size
        end

        # Get the desc
        #
        # @return [String, nil]
        def desc
          content_from 'ns:desc', :ns => self.class.registered_ns
        end

        # Set the desc
        #
        # @param [String, nil] desc the description of the file
        def desc=(desc)
          set_content_for :desc, desc
        end

        # Find or create range node
        #
        # @return [Si::Si::File::Range]
        def range
          Range.find_or_create self
        end
      end

      # Range stanza fragment
      class Range < XMPPNode
        register :range, 'http://jabber.org/protocol/si/profile/file-transfer'

        # Create a new Si::Si::File::Range object
        #
        # @param [XML::Node, nil] node a node to inherit from
        #
        # @return [Si::Si::File::Range]
        def self.new(offset = nil, length = nil)
          new_node = super :range

          case offset
          when Nokogiri::XML::Node
            new_node.inherit offset
          else
            new_node.offset = offset
            new_node.length = length
          end
          new_node
        end
        # Find or create range node in file node and converts it to Si::Si::File::Range
        #
        # @param [Si::Si::File] parent a file node where to find or create range
        #
        # @return [Si::Si::File::Range]
        def self.find_or_create(parent)
          if found_range = parent.at_xpath('//ns:range', :ns => self.registered_ns)
            range = self.new found_range
            found_range.remove
          else
            range = self.new
          end
          parent << range

          range
        end

        # Get the offset
        #
        # @return [Fixnum, nil]
        def offset
          if (o = read_attr(:offset)) && (o =~ /^\d+$/)
            o.to_i
          else
            nil
          end
        end

        # Set the offset
        #
        # @param [Fixnum, nil] offset the position, in bytes, to start transferring the file data from
        def offset=(offset)
          write_attr :offset, offset
        end

        # Get the length
        #
        # @return [Fixnum, nil]
        def length
          if (l = read_attr(:length)) && (l =~ /^\d+$/)
            l.to_i
          else
            nil
          end
        end

        # Set the length
        #
        # @param [Fixnum, nil] length the number of bytes to retrieve starting at offset
        def length=(length)
          write_attr :length, length
        end
      end
    end
  end
end
end
end
