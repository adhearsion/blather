module Blather
class Stanza

  # # PusSub Error Stanza
  #
  # @private
  class PubSubErrors < PubSub
    def node
      read_attr :node
    end

    def node=(node)
      write_attr :node, node
    end
  end  # PubSubErrors

end  # Stanza
end  # Blather
