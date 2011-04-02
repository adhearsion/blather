require File.join(File.dirname(__FILE__), *%w[.. .. blather])

module Blather
  # # Blather Client
  #
  # Blather's Client class provides a set of helpers for working with common
  # XMPP tasks such as setting up and starting the connection, settings
  # status, registering and dispatching filters and handlers and roster
  # management.
  #
  # Client can be used separately from the DSL if you'd like to implement your
  # own DSL Here's the echo example using the client without the DSL:
  #
  #     require 'blather/client/client'
  #     client = Client.setup 'echo@jabber.local', 'echo'
  #
  #     client.register_handler(:ready) do
  #       puts "Connected ! send messages to #{client.jid.stripped}."
  #     end
  #
  #     client.register_handler :subscription, :request? do |s|
  #       client.write s.approve!
  #     end
  #
  #     client.register_handler :message, :chat?, :body => 'exit' do |m|
  #       client.write Blather::Stanza::Message.new(m.from, 'Exiting...')
  #       client.close
  #     end
  #
  #     client.register_handler :message, :chat?, :body do |m|
  #       client.write Blather::Stanza::Message.new(m.from, "You sent: #{m.body}")
  #     end
  #
  class Client
    attr_reader :jid,
                :roster,
                :caps

    # Create a new client and set it up
    #
    # @param [Blather::JID, #to_s] jid the JID to authorize with
    # @param [String] password the password to authorize with
    # @param [String] host if this isn't set it'll be resolved off the JID's
    # domain
    # @param [Fixnum, String] port the port to connect to.
    #
    # @return [Blather::Client]
    def self.setup(jid, password, host = nil, port = nil)
      self.new.setup(jid, password, host, port)
    end

    def initialize  # @private
      @state = :initializing

      @status = Stanza::Presence::Status.new
      @handlers = {}
      @tmp_handlers = {}
      @filters = {:before => [], :after => []}
      @roster = Roster.new self
      @caps = Caps.new

      setup_initial_handlers
    end

    # Get the current status. Taken from the `state` attribute of Status
    def status
      @status.state
    end

    # Set the status. Status can be set with either a single value or an array
    # containing
    #
    # [state, message, to].
    def status=(state)
      state, msg, to = state

      status = Stanza::Presence::Status.new state, msg
      status.to = to
      @status = status unless to

      write status
    end

    # Start the connection.
    #
    # The stream type used is based on the JID. If a node exists it uses
    # Blather::Stream::Client otherwise Blather::Stream::Component
    def run
      raise 'not setup!' unless setup?
      klass = @setup[0].node ? Blather::Stream::Client : Blather::Stream::Component
      klass.start self, *@setup
    end
    alias_method :connect, :run

    # Register a filter to be run before or after the handler chain is run.
    #
    # @param [<:before, :after>] type the filter type
    # @param [Symbol, nil] handler set the filter on a specific handler
    # @param [guards] guards take a look at the guards documentation
    # @yield [Blather::Stanza] stanza the incomming stanza
    def register_filter(type, handler = nil, *guards, &filter)
      unless [:before, :after].include?(type)
        raise "Invalid filter: #{type}. Must be :before or :after"
      end
      @filters[type] << [guards, handler, filter]
    end

    # Register a temporary handler. Temporary handlers are based on the ID of
    # the JID and live only until a stanza with said ID is received.
    #
    # @param [#to_s] id the ID of the stanza that should be handled
    # @yield [Blather::Stanza] stanza the incomming stanza
    def register_tmp_handler(id, &handler)
      @tmp_handlers[id.to_s] = handler
    end

    # Clear handlers with given guards
    #
    # @param [Symbol, nil] type remove filters for a specific handler
    # @param [guards] guards take a look at the guards documentation
    def clear_handlers(type, *guards)
      @handlers[type].delete_if { |g, _| g == guards }
    end

    # Register a handler
    #
    # @param [Symbol, nil] type set the filter on a specific handler
    # @param [guards] guards take a look at the guards documentation
    # @yield [Blather::Stanza] stanza the incomming stanza
    def register_handler(type, *guards, &handler)
      check_handler type, guards
      @handlers[type] ||= []
      @handlers[type] << [guards, handler]
    end

    # Write data to the stream
    #
    # @param [#to_xml, #to_s] stanza the content to send down the wire
    def write(stanza)
      self.stream.send(stanza)
    end

    # Helper that will create a temporary handler for the stanza being sent
    # before writing it to the stream.
    #
    #     client.write_with_handler(stanza) { |s| "handle stanza here" }
    #
    # is equivalent to:
    #
    #     client.register_tmp_handler(stanza.id) { |s| "handle stanza here" }
    #     client.write stanza
    #
    # @param [Blather::Stanza] stanza the stanza to send down the wire
    # @yield [Blather::Stanza] stanza the reply stanza
    def write_with_handler(stanza, &handler)
      register_tmp_handler stanza.id, &handler
      write stanza
    end

    # Close the connection
    def close
      self.stream.close_connection_after_writing
    end

    def post_init(stream, jid = nil)  # @private
      @stream = stream
      @jid = JID.new(jid) if jid
      self.jid.node ? client_post_init : ready!
    end

    def unbind  # @private
      call_handler_for(:disconnected, nil) || (EM.reactor_running? && EM.stop)
    end

    def receive_data(stanza)  # @private
      catch(:halt) do
        run_filters :before, stanza
        handle_stanza stanza
        run_filters :after, stanza
      end
    end

    def setup?  # @private
      @setup.is_a? Array
    end

    def setup(jid, password, host = nil, port = nil)  # @private
      @jid = JID.new(jid)
      @setup = [@jid, password]
      @setup << host if host
      @setup << port if port
      self
    end

  protected
    def stream  # @private
      @stream || raise('Stream not ready!')
    end

    def check_handler(type, guards)  # @private
      Blather.logger.warn "Handler for type \"#{type}\" will never be called as it's not a registered type" unless current_handlers.include?(type)
      check_guards guards
    end

    def current_handlers  # @private
      [:ready, :disconnected] + Stanza.handler_list + BlatherError.handler_list
    end

    def setup_initial_handlers  # @private
      register_handler :error do |err|
        raise err
      end

      # register_handler :iq, :type => [:get, :set] do |iq|
      #   write StanzaError.new(iq, 'service-unavailable', :cancel).to_node
      # end

      register_handler :status do |status|
        roster[status.from].status = status if roster[status.from]
        nil
      end

      register_handler :roster do |node|
        roster.process node
      end
    end

    def ready!  # @private
      @state = :ready
      call_handler_for :ready, nil
    end

    def client_post_init  # @private
      write_with_handler Stanza::Iq::Roster.new do |node|
        roster.process node
        write @status
        ready!
      end
    end

    def run_filters(type, stanza)  # @private
      @filters[type].each do |guards, handler, filter|
        next if handler && !stanza.handler_hierarchy.include?(handler)
        catch(:pass) { call_handler filter, guards, stanza }
      end
    end

    def handle_stanza(stanza)  # @private
      if handler = @tmp_handlers.delete(stanza.id)
        handler.call stanza
      else
        stanza.handler_hierarchy.each do |type|
          break if call_handler_for(type, stanza)
        end
      end
    end

    def call_handler_for(type, stanza)  # @private
      return unless handler = @handlers[type]
      handler.find do |guards, handler|
        catch(:pass) { call_handler handler, guards, stanza }
      end
    end

    def call_handler(handler, guards, stanza)  # @private
      if guards.first.respond_to?(:to_str)
        result = stanza.find(*guards)
        handler.call(stanza, result) unless result.empty?
      else
        handler.call(stanza) unless guarded?(guards, stanza)
      end
    end

    # If any of the guards returns FALSE this returns true
    # the logic is reversed to allow short circuiting
    # (why would anyone want to loop over more values than necessary?)
    #
    # @private
    def guarded?(guards, stanza)
      guards.find do |guard|
        case guard
        when Symbol
          !stanza.__send__(guard)
        when Array
          # return FALSE if any item is TRUE
          !guard.detect { |condition| !guarded?([condition], stanza) }
        when Hash
          # return FALSE unless any inequality is found
          guard.find do |method, test|
            value = stanza.__send__(method)
            # last_match is the only method found unique to Regexp classes
            if test.class.respond_to?(:last_match)
              !(test =~ value.to_s)
            elsif test.is_a?(Array)
              !test.include? value
            else
              test != value
            end
          end
        when Proc
          !guard.call(stanza)
        end
      end
    end

    def check_guards(guards)  # @private
      guards.each do |guard|
        case guard
        when Array
          guard.each { |g| check_guards([g]) }
        when Symbol, Proc, Hash, String
          nil
        else
          raise "Bad guard: #{guard.inspect}"
        end
      end
    end

    class Caps < Blather::Stanza::DiscoInfo
      def self.new
        super :result
      end

      def ver
        generate_ver identities, features
      end

      def node=(node)
        @bare_node = node
        super "#{node}##{ver}"
      end

      def identities=(identities)
        super identities
        regenerate_full_node
      end

      def features=(features)
        super features
        regenerate_full_node
      end

      def c
        Blather::Stanza::Presence::C.new @bare_node, ver
      end

      private

      def regenerate_full_node
        self.node = @bare_node
      end

      def generate_ver_str(identities, features, forms = [])
        # 1.  Initialize an empty string S.
        s = ''

        # 2. Sort the service discovery identities by category and
        # then by type (if it exists) and then by xml:lang (if it
        # exists), formatted as CATEGORY '/' [TYPE] '/' [LANG] '/'
        # [NAME]. Note that each slash is included even if the TYPE,
        # LANG, or NAME is not included.
        identities.sort! do |identity1, identity2|
          cmp_result = nil
          [:category, :type, :xml_lang, :name].each do |field|
            value1 = identity1.send(field)
            value2 = identity2.send(field)

            if value1 != value2
              cmp_result = value1 <=> value2
              break
            end
          end
          cmp_result
        end

        # 3. For each identity, append the 'category/type/lang/name' to
        # S, followed by the '<' character.
        s += identities.collect do |identity|
          [:category, :type, :xml_lang, :name].collect do |field|
            identity.send(field).to_s
          end.join('/') + '<'
        end.join

        # 4. Sort the supported service discovery features.
        features.sort! { |feature1, feature2| feature1.var <=> feature2.var }

        # 5. For each feature, append the feature to S, followed by the
        # '<' character.
        s += features.collect { |feature| feature.var.to_s + '<' }.join

        # 6. If the service discovery information response includes
        # XEP-0128 data forms, sort the forms by the FORM_TYPE (i.e., by
        # the XML character data of the <value/> element).
        forms.sort! do |form1, form2|
          fform_type1 = form1.field 'FORM_TYPE'
          fform_type2 = form2.field 'FORM_TYPE'
          form_type1 = fform_type1 ? fform_type1.values.to_s : nil
          form_type2 = fform_type2 ? fform_type2.values.to_s : nil
          form_type1 <=> form_type2
        end

        # 7. For each extended service discovery information form:
        forms.each do |form|
          # 7.1. Append the XML character data of the FORM_TYPE field's
          # <value/> element, followed by the '<' character.
          fform_type = form.field 'FORM_TYPE'
          form_type = fform_type ? fform_type.values.to_s : nil
          s += "#{form_type}<"

          # 7.2. Sort the fields by the value of the "var" attribute
          fields = form.fields.sort { |field1, field2| field1.var <=> field2.var }

          # 7.3. For each field:
          fields.each do |field|
            # 7.3.1. Append the value of the "var" attribute, followed by
            # the '<' character.
            s += "#{field.var}<"

            # 7.3.2. Sort values by the XML character data of the <value/> element
            # values = field.values.sort { |value1, value2| value1 <=> value2 }

            # 7.3.3. For each <value/> element, append the XML character
            # data, followed by the '<' character.
            # s += values.collect { |value| "#{value}<" }.join
            s += "#{field.value}<"
          end
        end
        s
      end

      def generate_ver(identities, features, forms = [], hash = 'sha-1')
        s = generate_ver_str identities, features, forms

        # 9. Compute the verification string by hashing S using the
        # algorithm specified in the 'hash' attribute (e.g., SHA-1 as
        # defined in RFC 3174). The hashed data MUST be generated
        # with binary output and encoded using Base64 as specified in
        # Section 4 of RFC 4648 (note: the Base64 output MUST NOT
        # include whitespace and MUST set padding bits to zero).

        # See http://www.iana.org/assignments/hash-function-text-names
        hash_klass = case hash
                       when 'md2' then nil
                       when 'md5' then Digest::MD5
                       when 'sha-1' then Digest::SHA1
                       when 'sha-224' then nil
                       when 'sha-256' then Digest::SHA256
                       when 'sha-384' then Digest::SHA384
                       when 'sha-512' then Digest::SHA512
                     end
        hash_klass ? [hash_klass::digest(s)].pack('m').strip : nil
      end
    end # Caps
  end  # Client

end  # Blather
