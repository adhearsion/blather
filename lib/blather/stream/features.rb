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
      # FIX for Tigase bind error
      # The problem is that Tigase sends such stanza:
      # <features>
      #   <ver xmlns="urn:xmpp:features:rosterver"/>
      #   <session xmlns="urn:ietf:params:xml:ns:xmpp-session"/>
      #   <bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/>
      # </features>
      # And what Blather does it sends session iq immediately without binding
      # In normal query should be <bind/> note before <session/>
      # So what I fixed here is just sorting <bind/> before <session/>

      bind = @features.children.detect do |node|
        node.name == 'bind' && node.namespace.href == 'urn:ietf:params:xml:ns:xmpp-bind'
      end
      session = @features.children.detect do |node|
        node.name == 'session' && node.namespace.href == 'urn:ietf:params:xml:ns:xmpp-session'
      end
      if bind && session && @features.children.last != session
        @features.children.after session
      end

      @idx = @idx ? @idx+1 : 0
      if stanza = @features.children[@idx]
        if stanza.namespaces['xmlns'] && (klass = self.class.from_namespace(stanza.namespaces['xmlns']))
          @feature = klass.new(
            @stream,
            proc {
              if (klass == Blather::Stream::Register && stanza = feature?(:mechanisms))
                @idx = @features.children.index(stanza)
                @feature = Blather::Stream::SASL.new @stream, proc { next! }, @fail
                @feature.receive_data stanza
              else
                next!
              end
            },
            (klass == Blather::Stream::SASL && feature?(:register)) ? proc { next! } : @fail
          )
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

    def feature?(feature)
      @features && @features.children.find { |v| v.element_name == feature.to_s }
    end
  end

end #Stream
end #Blather
