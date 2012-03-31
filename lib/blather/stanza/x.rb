module Blather
class Stanza
  # # X Stanza
  #
  # [XEP-0004 Data Forms](http://xmpp.org/extensions/xep-0004.html)
  #
  # Data Form node that allows for semi-structured data exchange
  #
  # @handler :x
  class X < XMPPNode
    register :x, 'jabber:x:data'

    # @private
    VALID_TYPES = [:cancel, :form, :result, :submit].freeze

    # Create a new X node
    # @param [:cancel, :form, :result, :submit, nil] type the x:form type
    # @param [Array<Array, X::Field>, nil] fields a list of fields.
    # These are passed directly to X::Field.new
    # @return [X] a new X stanza
    def self.new(type = nil, fields = [])
      new_node = super :x

      case type
      when Nokogiri::XML::Node
        new_node.inherit type
      when Hash
        new_node.type = type[:type]
        new_node.fields = type[:fields]
      else
        new_node.type = type
        new_node.fields = fields
      end
      new_node
    end

    # Find the X node on the parent or create a new one
    #
    # @param [Blather::Stanza] parent the parent node to search under
    # @return [Blather::Stanza::X]
    def self.find_or_create(parent)
      if found_x = parent.find_first('//ns:x', :ns => self.registered_ns)
        x = self.new found_x
        found_x.remove
      else
        x = self.new
      end
      parent << x
      x
    end

    # The Form's type
    # @return [Symbol]
    def type
      read_attr :type, :to_sym
    end

    # Set the Form's type
    # @param [:cancel, :form, :result, :submit] type the new type for the form
    def type=(type)
      if type && !VALID_TYPES.include?(type.to_sym)
        raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}"
      end
      write_attr :type, type
    end

    # List of field objects
    # @return [Blather::Stanza::X::Field]
    def fields
      self.find('ns:field', :ns => self.class.registered_ns).map do |field|
        Field.new(field)
      end
    end

    # Find a field by var
    # @param var the var for the field you wish to find
    def field(var)
      fields.detect { |f| f.var == var }
    end

    # Add an array of fields to form
    # @param fields the array of fields, passed directly to Field.new
    def fields=(fields)
      remove_children :field
      [fields].flatten.each do |field|
        self << (f = Field.new(field))
        f.namespace = self.namespace
      end
    end

    # Check if the x is of type :cancel
    #
    # @return [true, false]
    def cancel?
      self.type == :cancel
    end

    # Check if the x is of type :form
    #
    # @return [true, false]
    def form?
      self.type == :form
    end

    # Check if the x is of type :result
    #
    # @return [true, false]
    def result?
      self.type == :result
    end

    # Check if the x is of type :submit
    #
    # @return [true, false]
    def submit?
      self.type == :submit
    end

    # Retrieve the form's instructions
    #
    # @return [String]
    def instructions
      content_from 'ns:instructions', :ns => self.registered_ns
    end

    # Set the form's instructions
    #
    # @param [String] instructions the form's instructions
    def instructions=(instructions)
      self.remove_children :instructions
      if instructions
        self << (i = XMPPNode.new(:instructions, self.document))
        i.namespace = self.namespace
        i << instructions
      end
    end

    # Retrieve the form's title
    #
    # @return [String]
    def title
      content_from 'ns:title', :ns => self.registered_ns
    end

    # Set the form's title
    #
    # @param [String] title the form's title
    def title=(title)
      self.remove_children :title
      if title
        self << (t = XMPPNode.new(:title))
        t.namespace = self.namespace
        t << title
      end
    end

    # Field stanza fragment
    class Field < XMPPNode
      register :field, 'jabber:x:data'
      # @private
      VALID_TYPES = [:boolean, :fixed, :hidden, :"jid-multi", :"jid-single", :"list-multi", :"list-single", :"text-multi", :"text-private", :"text-single"].freeze

      # Create a new X Field
      # @overload new(node)
      #   Imports the XML::Node to create a Field object
      #   @param [XML::Node] node the node object to import
      # @overload new(opts = {})
      #   Creates a new Field using a hash of options
      #   @param [Hash] opts a hash of options
      #   @option opts [String] :var the variable for the field
      #   @option opts [:boolean, :fixed, :hidden, :"jid-multi", :"jid-single", :"list-multi", :"list-single", :"text-multi", :"text-private", :"text-single"] :type the type of the field
      #   @option opts [String] :label the label for the field
      #   @option [String, nil] :value the value for the field
      #   @option [String, nil] :description the description for the field
      #   @option [true, false, nil] :required the required flag for the field
      #   @param [Array<Array, X::Field::Option>, nil] :options a list of field options.
      #   These are passed directly to X::Field::Option.new
      # @overload new(type, var = nil, label = nil)
      #   Create a new Field by name
      #   @param [String, nil] var the variable for the field
      #   @param [:boolean, :fixed, :hidden, :"jid-multi", :"jid-single", :"list-multi", :"list-single", :"text-multi", :"text-private", :"text-single"] type the type of the field
      #   @param [String, nil] label the label for the field
      #   @param [String, nil] value the value for the field
      #   @param [String, nil] description the description for the field
      #   @param [true, false, nil] required the required flag for the field
      #   @param [Array<Array, X::Field::Option>, nil] options a list of field options.
      #   These are passed directly to X::Field::Option.new
      def self.new(var, type = nil, label = nil, value = nil, description = nil, required = false, options = [])
        new_node = super :field

        case var
        when Nokogiri::XML::Node
          new_node.inherit var
        when Hash
          new_node.var = var[:var]
          new_node.type = var[:type]
          new_node.label = var[:label]
          new_node.value = var[:value]
          new_node.desc = var[:description]
          new_node.required = var[:required]
          new_node.options = var[:options]
        else
          new_node.var = var
          new_node.type = type
          new_node.label = label
          new_node.value = value
          new_node.desc = description
          new_node.required = required
          new_node.options = options
        end
        new_node
      end

      # The Field's type
      # @return [String]
      def type
        read_attr :type
      end

      # Set the Field's type
      # @param [#to_sym] type the new type for the field
      def type=(type)
        if type && !VALID_TYPES.include?(type.to_sym)
          raise ArgumentError, "Invalid Type (#{type}), use: #{VALID_TYPES*' '}"
        end
        write_attr :type, type
      end

      # The Field's var
      # @return [String]
      def var
        read_attr :var
      end

      # Set the Field's var
      # @param [String] var the new var for the field
      def var=(var)
        write_attr :var, var
      end

      # The Field's label
      # @return [String]
      def label
        read_attr :label
      end

      # Set the Field's label
      # @param [String] label the new label for the field
      def label=(label)
        write_attr :label, label
      end

      # Get the field's value
      #
      # @param [String]
      def value
        if self.namespace
          content_from 'ns:value', :ns => self.namespace.href
        else
          content_from :value
        end
      end

      # Set the field's value
      #
      # @param [String] value the field's value
      def value=(value)
        self.remove_children :value
        if value
          self << (v = XMPPNode.new(:value))
          v.namespace = self.namespace
          v << value
        end
      end

      # Get the field's description
      #
      # @param [String]
      def desc
        if self.namespace
          content_from 'ns:desc', :ns => self.namespace.href
        else
          content_from :desc
        end
      end

      # Set the field's description
      #
      # @param [String] description the field's description
      def desc=(description)
        self.remove_children :desc
        if description
          self << (d = XMPPNode.new(:desc))
          d.namespace = self.namespace
          d << description
        end
      end

      # Get the field's required flag
      #
      # @param [true, false]
      def required?
        if self.namespace
          !self.find_first('ns:required', :ns => self.namespace.href).nil?
        else
          !self.find_first('required').nil?
        end
      end

      # Set the field's required flag
      #
      # @param [true, false] required the field's required flag
      def required=(required)
        self.remove_children(:required) unless required
        self << XMPPNode.new(:required) if required
      end

      # Extract list of option objects
      #
      # @return [Blather::Stanza::X::Field::Option]
      def options
        if self.namespace
          self.find('ns:option', :ns => self.namespace.href)
        else
          self.find('option')
        end.map { |f| Option.new(f) }
      end

      # Add an array of options to field
      # @param options the array of options, passed directly to Option.new
      def options=(options)
        remove_children :option
        if options
          Array(options).each { |o| self << Option.new(o) }
        end
      end

      # Compare two Field objects by type, var and label
      # @param [X::Field] o the Field object to compare against
      # @return [true, false]
      def eql?(o, *fields)
        super o, *(fields + [:type, :var, :label, :desc, :required?, :value])
      end

      # Option stanza fragment
      class Option < XMPPNode
        register :option, 'jabber:x:data'
        # Create a new X Field Option
        # @overload new(node)
        #   Imports the XML::Node to create a Field option object
        #   @param [XML::Node] node the node object to import
        # @overload new(opts = {})
        #   Creates a new Field option using a hash of options
        #   @param [Hash] opts a hash of options
        #   @option opts [String] :value the value of the field option
        #   @option opts [String] :label the human readable label for the field option
        # @overload new(value, label = nil)
        #   Create a new Field option by name
        #   @param [String] value the value of the field option
        #   @param [String, nil] label the human readable label for the field option
        def self.new(value, label = nil)
          new_node = super :option

          case value
          when Nokogiri::XML::Node
            new_node.inherit value
          when Hash
            new_node.value = value[:value]
            new_node.label = value[:label]
          else
            new_node.value = value
            new_node.label = label
          end
          new_node
        end

        # The Field Option's value
        # @return [String]
        def value
          if self.namespace
            content_from 'ns:value', :ns => self.namespace.href
          else
            content_from :value
          end
        end

        # Set the Field Option's value
        # @param [String] value the new value for the field option
        def value=(value)
          self.remove_children :value
          if value
            self << (v = XMPPNode.new(:value))
            v.namespace = self.namespace
            v << value
          end
        end

        # The Field Option's label
        # @return [String]
        def label
          read_attr :label
        end

        # Set the Field Option's label
        # @param [String] label the new label for the field option
        def label=(label)
          write_attr :label, label
        end
      end # Option
    end # Field
  end # X

end #Stanza
end
