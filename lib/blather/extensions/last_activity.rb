module Blather
  module Extensions

    module LastActivity
      def self.included(base)
        base.class_eval do
          @@last_activity = Time.now

          alias_method :send_data_without_activity, :send_data
          def send_data(data)
            @@last_activity = Time.now
            send_data_without_activity data
          end
        end
      end

      def last_activity
        (Time.now - @@last_activity).to_i
      end

      def receive_last_activity(stanza)
        send_data stanza.reply!(last_activity) if stanza.type == 'get'
      end
    end #LastActivity

    class LastActivityStanza < Query
      register :last_activity, nil, 'jabber:iq:last'

      def self.new(type = :get, seconds = nil)
        elem = super type
        elem.seconds = seconds
        elem
      end

      def seconds=(seconds)
        query.attributes.remove :seconds
        query['seconds'] = seconds.to_i.to_s if seconds
      end

      def seconds
        (query['seconds'] || 0).to_i
      end

      def reply(seconds)
        elem = super()
        elem.last_activity = seconds
      end

      def reply!(seconds)
        self.last_activity = seconds
        super()
      end
    end #LastActivityStanza
  end
end

Blather::Client.__send__ :include, Blather::Extensions::LastActivity
