module Blather
class Stream

  # @private
  class Features
    @@features = {}
    def self.register(ns)
      @@features[ns] = self
    end

    def self.from_namespace(ns)
      @@features[ns]
    end

    def initialize(stream, succeed, fail)
      @stream = stream
      @succeed = succeed
      @fail = fail
    end

    def receive_data(stanza)
      if @feature
        @feature.receive_data stanza
      else
        @features ||= stanza
        next!
      end
    end

    def next!
      @idx = @idx ? @idx+1 : 0
      if stanza = @features.children[@idx]
        if stanza.namespaces['xmlns'] && (klass = self.class.from_namespace(stanza.namespaces['xmlns']))
          @feature = klass.new @stream, proc { next! }, @fail
          @feature.receive_data stanza
        else
          next!
        end
      else
        succeed!
      end
    end

    def succeed!
      @succeed.call
    end

    def fail!(msg)
      @fail.call msg
    end
  end

end #Stream
end #Blather
