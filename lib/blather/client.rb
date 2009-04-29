require File.join(File.dirname(__FILE__), *%w[client dsl])

include Blather::DSL

at_exit do
  unless client.setup?
    if ARGV.length < 2
      puts "Run with #{$0} user@server/resource password [host] [port]"
    else
      client.setup(*ARGV).run
    end
  end
end
