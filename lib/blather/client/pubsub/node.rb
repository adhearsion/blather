module Blather
class Client
class PubSub

  class Node
    attr_accessor :path

    def initialize(path)
      @path = path
    end

    def info(&block)
      DSL.client.write_with_handler Stanza::DiscoInfo.new(:get, path), &block
    end

    def items(&block)
      DSL.client.write_with_handler Stanza::PubSub.items(path), &block
    end

    def nodes(&block)
      DSL.client.write_with_handler Stanza::DiscoItems.new(:get, path), &block
    end
  end

end #PubSub
end #Client
end #Blather
