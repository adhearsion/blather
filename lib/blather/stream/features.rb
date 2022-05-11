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
      @stream, @succeed, @fail = stream, succeed, fail
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
      if starttls = @features.at_xpath("tls:starttls",{"tls" => "urn:ietf:params:xml:ns:xmpp-tls"})
       @feature = TLS.new(@stream, nil, @fail)
       @feature.receive_data(starttls)
       return
      end

      bind = @features.at_xpath('ns:bind', ns: 'urn:ietf:params:xml:ns:xmpp-bind')
      session = @features.at_xpath('ns:session', ns: 'urn:ietf:params:xml:ns:xmpp-session')
      if bind && session && @features.children.last != session
        bind.after session
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
