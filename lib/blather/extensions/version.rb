module Blather
  module Extensions

    module Version
      def self.included(base)
        base.class_eval do
          @@version = {}

          def self.version(name, ver, os = nil)
            @@version = {:name => name, :version => ver, :os => os}
          end

          add_callback(:iq, 100) do |c, s|
            if s.detect { |n| n['xmlns'] == 'jabber:iq:version' }
              ver = VersionStanza.new('result', c.version)
              ver.id = s.id
              ver.from = c.jid
              ver.to = s.from
              c.send_data ver
            end
          end
        end
      end

      def version
        @@version
      end
    end #Version

    class VersionStanza < Iq
      def self.new(type = 'result', ver = {})
        elem = super(type)

        query = XML::Node.new('query')
        query.xmlns = 'jabber:iq:version'
        elem << query

        elem.name = ver[:name] if ver[:name]
        elem.version = ver[:version] if ver[:version]
        elem.os = ver[:os] if ver[:os]

        elem
      end

      def query
        @query ||= self.detect { |n| n.name == 'query' }
      end

      def name=(name)
        query.each { |n| n.remove! or break if n.name == 'name' }
        query << XML::Node.new('name', name)
      end

      def name
        if name = query.detect { |n| n.name == 'name' }
          name.content
        end
      end

      def version=(version)
        query.each { |n| n.remove! or break if n.name == 'version' }
        query << XML::Node.new('version', version)
      end

      def version
        if version = query.detect { |n| n.version == 'version' }
          version.content
        end
      end

      def os=(os)
        query.each { |n| n.remove! or break if n.name == 'os' }
        query << XML::Node.new('os', os)
      end

      def os
        if os = query.detect { |n| n.os == 'os' }
          os.content
        end
      end
    end #VersionStanza
  end
end

Blather::Client.__send__ :include, Blather::Extensions::Version
