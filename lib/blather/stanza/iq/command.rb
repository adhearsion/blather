module Blather
class Stanza
class Iq

  # # Command Stanza
  #
  # [XEP-0050 Ad-Hoc Commands](http://xmpp.org/extensions/xep-0050.html)
  #
  # This is a base class for any command based Iq stanzas. It provides a base set
  # of methods for working with command stanzas
  #
  # @handler :command
  class Command < Iq
    # @private
    VALID_ACTIONS = [:cancel, :execute, :complete, :next, :prev].freeze
    # @private
    VALID_STATUS = [:executing, :completed, :canceled].freeze
    # @private
    VALID_NOTE_TYPES = [:info, :warn, :error].freeze

    register :command, :command, 'http://jabber.org/protocol/commands'

    # Overrides the parent method to ensure a command node is created
    #
    # @param [:get, :set, :result, :error, nil] type the IQ type
    # @param [String] node the name of the node
    # @param [:cancel, :execute, :complete, :next, :prev, nil] action the command's action
    # @return [Command] a new Command stanza
    def self.new(type = :set, node = nil, action = :execute)
      new_node = super type
      new_node.command
      new_node.node = node
      new_node.action = action
      new_node
    end

    # Overrides the parent method to ensure the current command node is destroyed
    # and the action is set to execute if no action provided
    #
    # @see Blather::Stanza::Iq#inherit
    def inherit(node)
      command.remove
      super
      self.action = :execute unless self.action
      self
    end

    # Overrides the parent method to ensure the reply has no action
    #
    # @param [Hash] opts options to pass to reply!
    # @option opts [Boolean] :remove_children Wether or not to remove child nodes when replying
    #
    # @return [self]
    def reply!(opts = {})
      opts = {:remove_children => false}.merge opts
      super
      self.action = nil
      self.command.children.remove
      new_sessionid! if !sessionid
      self
    end

    # Command node accessor
    # If a command node exists it will be returned.
    # Otherwise a new node will be created and returned
    #
    # @return [Blather::XMPPNode]
    def command
      c = if self.class.registered_ns
        find_first('ns:command', :ns => self.class.registered_ns)
      else
        find_first('command')
      end

      unless c
        (self << (c = XMPPNode.new('command', self.document)))
        c.namespace = self.class.registered_ns
      end
      c
    end

    # Get the name of the node
    #
    # @return [String, nil]
    def node
      command[:node]
    end

    # Set the name of the node
    #
    # @param [String, nil] node the new node name
    def node=(node)
      command[:node] = node
    end

    # Get the sessionid of the command
    #
    # @return [String, nil]
    def sessionid
      command[:sessionid]
    end

    # Check if there is a sessionid set
    #
    # @return [true, false]
    def sessionid?
      !sessionid.nil?
    end

    # Set the sessionid of the command
    #
    # @param [String, nil] sessionid the new sessionid
    def sessionid=(sessionid)
      command[:sessionid] = sessionid
    end

    # Generate a new session ID (SHA-1 hash)
    def new_sessionid!
      self.sessionid = "commandsession-#{id}"
    end

    # Get the action of the command
    #
    # @return [Symbol, nil]
    def action
      (val = command[:action]) && val.to_sym
    end

    # Check if the command action is :cancel
    #
    # @return [true, false]
    def cancel?
      self.action == :cancel
    end

    # Check if the command action is :execute
    #
    # @return [true, false]
    def execute?
      self.action == :execute
    end

    # Check if the command action is :complete
    #
    # @return [true, false]
    def complete?
      self.action == :complete
    end

    # Check if the command action is :next
    #
    # @return [true, false]
    def next?
      self.action == :next
    end

    # Check if the command action is :prev
    #
    # @return [true, false]
    def prev?
      self.action == :prev
    end

    # Set the action of the command
    #
    # @param [:cancel, :execute, :complete, :next, :prev] action the new action
    def action=(action)
      if action && !VALID_ACTIONS.include?(action.to_sym)
        raise ArgumentError, "Invalid Action (#{action}), use: #{VALID_ACTIONS*' '}"
      end
      command[:action] = action
    end

    # Get the status of the command
    #
    # @return [Symbol, nil]
    def status
      ((val = command[:status]) && val.to_sym) || :executing
    end

    # Check if the command status is :executing
    #
    # @return [true, false]
    def executing?
      self.status == :executing
    end

    # Check if the command status is :completed
    #
    # @return [true, false]
    def completed?
      self.status == :completed
    end

    # Check if the command status is :canceled
    #
    # @return [true, false]
    def canceled?
      self.status == :canceled
    end

    # Set the status of the command
    #
    # @param [:executing, :completed, :canceled] status the new status
    def status=(status)
      if status && !VALID_STATUS.include?(status.to_sym)
        raise ArgumentError, "Invalid Action (#{status}), use: #{VALID_STATUS*' '}"
      end
      command[:status] = status
    end

    # Command actions accessor
    # If a command actions element exists it will be returned.
    # Otherwise a new actions element will be created and returned
    #
    # @return [Blather::XMPPNode]
    def actions
      unless a = self.command.find_first('ns:actions', :ns => self.class.registered_ns)
        (self.command << (a = XMPPNode.new('actions', self.document)))
        a.namespace = self.command.namespace
      end
      a
    end

    # Get the command's allowed actions
    #
    # @return [Array<Symbol>]
    def allowed_actions
      ([:execute] + actions.children.map { |action| action.name.to_sym }).uniq
    end

    # Get the primary allowed action
    #
    # @return [Symbol]
    def primary_allowed_action
      (actions[:execute] || :execute).to_sym
    end

    # Set the primary allowed action
    #
    # This must be one of :prev, :next, :complete or :execute
    #
    # @param [#to_sym] a the primary allowed action
    def primary_allowed_action=(a)
      a = a.to_sym
      if a && ![:prev, :next, :complete, :execute].include?(a)
        raise ArgumentError, "Invalid Action (#{a}), use: #{[:prev, :next, :complete, :execute]*' '}"
      end
      actions[:execute] = a
    end

    # Add allowed actions to the command
    #
    # @param [[:prev, :next, :complete]] allowed_actions the new allowed actions
    def allowed_actions=(allowed_actions)
      allowed_actions = ([allowed_actions].flatten.map(&:to_sym) + [:execute]).uniq
      if (invalid_actions = allowed_actions - VALID_ACTIONS).size > 0
        raise ArgumentError, "Invalid Action(s) (#{invalid_actions*' '}), use: #{VALID_ACTIONS*' '}"
      end
      actions.children.map(&:remove)
      allowed_actions.each { |action| actions << XMPPNode.new(action.to_s) }
    end

    # Remove allowed actions from the command
    #
    # @param [[:prev, :next, :complete]] disallowed_actions the allowed actions to remove
    def remove_allowed_actions!
      actions.remove
    end

    # Command note accessor
    # If a command note exists it will be returned.
    # Otherwise a new note will be created and returned
    #
    # @return [Blather::XMPPNode]
    def note
      unless n = self.command.find_first('ns:note', :ns => self.class.registered_ns)
        (self.command << (n = XMPPNode.new('note', self.document)))
        n.namespace = self.command.namespace
      end
      n
    end

    # Get the note_type of the command
    #
    # @return [Symbol, nil]
    def note_type
      (val = note[:type]) && val.to_sym
    end

    # Check if the command status is :info
    #
    # @return [true, false]
    def info?
      self.note_type == :info
    end

    # Check if the command status is :warn
    #
    # @return [true, false]
    def warn?
      self.status == :warn
    end

    # Check if the command status is :error
    #
    # @return [true, false]
    def error?
      self.status == :error
    end

    # Set the note_type of the command
    #
    # @param [:executing, :completed, :canceled] note_type the new note_type
    def note_type=(note_type)
      if note_type && !VALID_NOTE_TYPES.include?(note_type.to_sym)
        raise ArgumentError, "Invalid Action (#{note_type}), use: #{VALID_NOTE_TYPES*' '}"
      end
      note[:type] = note_type
    end

    # Get the text of the command's note
    def note_text
      command.content_from('ns:note', ns: self.class.registered_ns)
    end

    # Set the command's note text
    #
    # @param [String] note_text the command's new note text
    def note_text=(note_text)
      note.content = note_text
    end

    # Returns the command's x:data form child
    def form
      X.find_or_create command
    end
  end #Command

end #Iq
end #Stanza
end #Blather
