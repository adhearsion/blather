require 'optparse'
require File.join(File.dirname(__FILE__), *%w[client dsl])

include Blather::DSL

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Run with #{$0} [options] user@server/resource password [host] [port]"

  opts.on('-D', '--debug', 'Run in debug mode (you will see all XMPP communication)') do
    options[:debug] = true
  end

  opts.on('-d', '--daemonize', 'Daemonize the process') do |daemonize|
    options[:daemonize] = daemonize
  end

  opts.on('--pid=[PID]', 'Write the PID to this file') do |pid|
    if !File.writable?(File.dirname(pid))
      $stderr.puts "Unable to write log file to #{pid}"
      exit 1
    end
    options[:pid] = pid
  end

  opts.on('--log=[LOG]', 'Write to the [LOG] file instead of stdout/stderr') do |log|
    if !File.writable?(File.dirname(log))
      $stderr.puts "Unable to write log file to #{log}"
      exit 1
    end
    options[:log] = log
  end
  
  opts.on('--certs=[CERTS]', 'Read in trusted certificates in order to ensure secure communication with the server') do |certs|
    if !File.directory?(certs)
      $stderr.puts "The certs directory path (#{certs}) is no good."
      exit 1
    end
    options[:log] = log
  end

  opts.on('--log=[LOG]', 'Write to the [LOG] file instead of stdout/stderr') do |log|
    if !File.writable?(File.dirname(log))
      $stderr.puts "Unable to write log file to #{log}"
      exit 1
    end
    options[:log] = log
  end
  
  opts.on_tail('-h', '--help', 'Show this message') do
    puts opts
    exit
  end

  opts.on_tail('-v', '--version', 'Show version') do
    require 'yaml'
    version = YAML.load_file File.join(File.dirname(__FILE__), %w[.. .. VERSION.yml])
    puts "Blather v#{version[:major]}.#{version[:minor]}.#{version[:patch]}"
    exit
  end
end
optparse.parse!

at_exit do
  unless client.setup?
    if ARGV.length < 2
      puts optparse
      exit 1
    end
    client.setup(*ARGV)
  end

  def run(options)
    $stdin.reopen "/dev/null"

    if options[:log]
      log = File.new(options[:log], 'a')
      log.sync = options[:debug]
      $stdout.reopen log
      $stderr.reopen $stdout
    end

    Blather.logger.level = Logger::DEBUG if options[:debug]

    trap(:INT) { EM.stop }
    trap(:TERM) { EM.stop }
    EM.run { client.run }
  end

  if options[:daemonize]
    pid = fork do
      Process.setsid
      exit if fork
      File.open(options[:pid], 'w') { |f| f << Process.pid } if options[:pid]
      run options
      FileUtils.rm(options[:pid]) if options[:pid]
    end
    ::Process.detach pid
    exit
  else
    run options
  end
end
