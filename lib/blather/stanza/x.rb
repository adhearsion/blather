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
        new_node.add_fields([type[:fields]])
      else
        new_node.type = type
        new_node.add_fields([fields])
      end
      new_node
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
      self.find('ns:field', :ns => self.class.registered_ns).map do |f|
        Field.new f
      end
    end

    # Add an array of fields to form
    # @param fields the array of fields, passed directly to Field.new
    def add_fields(fields = [])
      [fields].flatten.each { |f| self << Field.new(f) }
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
      if i = self.find_first('ns:instructions', :ns => self.class.registered_ns)
        i.children.inner_text
      end
    end

    # Set the form's instructions
    #
    # @param [String] instructions the form's instructions
    def instructions=(instructions)
      self.remove_children :instructions
      self << "<instructions>#{instructions}</instructions>"
    end

    # Retrieve the form's title
    #
    # @return [String]
    def title
      if t = self.find_first('ns:title', :ns => self.class.registered_ns)
        t.children.inner_text
      end
    end

    # Set the form's title
    #
    # @param [String] title the form's title
    def title=(title)
      self.remove_children :title
      self << "<title>#{title}</title>"
    end

    class Field < XMPPNode
      VALID_TYPES = [:boolean, :fixed, :hidden, :"jid-multi", :"jid-single", :"list-multi", :"list-single", :"text-multi", :"text-private", :"text-single"].freeze

      # Create a new X Field
      # @overload new(node)
      #   Imports the XML::Node to create a Field object
      #   @param [XML::Node] node the node object to import
      # @overload new(opts = {})
      #   Creates a new Field using a hash of options
      #   @param [Hash] opts a hash of options
      #   @option opts [:boolean, :fixed, :hidden, :"jid-multi", :"jid-single", :"list-multi", :"list-single", :"text-multi", :"text-private", :"text-single"] :type the type of the field
      #   @option opts [String] :var the variable for the field
      #   @option opts [String] :label the label for the field
      #   @option [String, nil] :value the value for the field
      #   @option [String, nil] :description the description for the field
      #   @option [true, false, nil] :required the required flag for the field
      #   @param [Array<Array, X::Field::Option>, nil] :options a list of field options.
      #   These are passed directly to X::Field::Option.new
      # @overload new(type, var = nil, label = nil)
      #   Create a new Field by name
      #   @param [:boolean, :fixed, :hidden, :"jid-multi", :"jid-single", :"list-multi", :"list-single", :"text-multi", :"text-private", :"text-single"] type the type of the field
      #   @param [String, nil] var the variable for the field
      #   @param [String, nil] label the label for the field
      #   @param [String, nil] value the value for the field
      #   @param [String, nil] description the description for the field
      #   @param [true, false, nil] required the required flag for the field
      #   @param [Array<Array, X::Field::Option>, nil] options a list of field options.
      #   These are passed directly to X::Field::Option.new
      def self.new(type, var = nil, label = nil, value = nil, description = nil, required = false, options = [])
        new_node = super :field

        case type
        when Nokogiri::XML::Node
          new_node.inherit type
        when Hash
          new_node.type = type[:type]
          new_node.var = type[:var]
          new_node.label = type[:label]
          new_node.value = type[:value]
          new_node.desc = type[:description]
          new_node.required! type[:required]
          new_node.add_options(type[:options])
        else
          new_node.type = type
          new_node.var = var
          new_node.label = label
          new_node.value = value
          new_node.desc = description
          new_node.required! required
          new_node.add_options(options)
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
        if v = self.find_first('value')
          v.children.inner_text
        end
      end

      # Set the field's value
      #
      # @param [String] value the field's value
      def value=(value)
        unless value == nil
          self.remove_children :value
          self << "<value>#{value}</value>"
        end
      end

      # Get the field's description
      #
      # @param [String]
      def desc
        if d = self.find_first('desc')
          d.children.inner_text
        end
      end

      # Set the field's description
      #
      # @param [String] description the field's description
      def desc=(description)
        unless description == nil
          self.remove_children :desc
          self << "<desc>#{description}</desc>"
        end
      end

      # Get the field's required flag
      #
      # @param [true, false]
      def required?
        self.find_first('required') ? true : false
      end

      # Set the field's required flag
      #
      # @param [true, false] required the field's required flag
      def required!(required = true)
        if self.find_first('required')
          if required==false
            self.remove_children :required
          end
        else
          if required==true
            self << "<required/>"
          end
        end
      end

      # Extract list of option objects
      #
      # @return [Blather::Stanza::X::Field::Option]
      def options
        self.find('option').map do |f|
          Option.new f
        end
      end

      # Add an array of options to field
      # @param options the array of options, passed directly to Option.new
      def add_options(options = [])
        [options].flatten.each { |o| self << Option.new(o) }
      end

      # Compare two Field objects by type, var and label
      # @param [X::Field] o the Field object to compare against
      # @return [true, false]
      def eql?(o)
        unless o.is_a?(self.class)
          raise "Cannot compare #{self.class} with #{o.class}"
        end

        o.type == self.type &&
        o.var == self.var &&
        o.label == self.label &&
        o.desc == self.desc &&
        o.required? == self.required? &&
        o.value == self.value
      end
      alias_method :==, :eql?

      class Option < XMPPNode
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
          if v = self.find_first('value')
            v.children.inner_text
          end
        end

        # Set the Field Option's value
        # @param [String] value the new value for the field option
        def value=(v)
          self.remove_children :value
          self << "<value>#{v}</value>"
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