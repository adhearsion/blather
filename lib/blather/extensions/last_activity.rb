module Blather
  module Extensions

    module LastActivity
      def self.included(base)
        base.class_eval do
          @@last_activity = Time.now

          alias_method :send_data_old, :send_data
          def send_data(data)
            @@last_activity = Time.now
            send_data_old data
          end

          add_callback(:iq, 100) do |c, s|
            if s.detect { |n| n['xmlns'] == 'jabber:iq:last' }
              ver = LastActivityStanza.new('result', c.last_activity)
              ver.id = s.id
              ver.from = c.jid
              ver.to = s.from
              c.send_data ver
            end
          end
        end
      end

      def last_activity
        (Time.now - @@last_activity).to_i
      end
    end #LastActivity

    class LastActivityStanza < Iq
      def self.new(type = 'result', seconds = 0)
        elem = super(type)

        query = XML::Node.new('query')
        query.xmlns = 'jabber:iq:version'
        elem << query

        elem.seconds = seconds

        elem
      end

      def query
        @query ||= self.detect { |n| n.name == 'query' }
      end

      def seconds=(seconds)
        query.attributes.each { |n| n.remove! or break if n.name == 'seconds' }
        query['seconds'] = seconds.to_s
      end

      def name
        query['seconds']
      end
    end #LastActivityStanza
  end
end

Blather::Client.__send__ :include, Blather::Extensions::LastActivity
