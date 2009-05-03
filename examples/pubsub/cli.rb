#!/usr/bin/env ruby

require 'blather/client'

#ls
#cd
#cat
#Blather::LOG.level = Logger::DEBUG
module CliHandler
  include EM::Protocols::LineText2

  def ls(node)
    pubsub.node(parse_dir(node)) do |result|
      cur = node.split('/')
      puts
      puts result.items.map { |i| (i.node.split('/') - cur).join('/') }.join("\n")
      start_line
    end
  end

  def cd(node)
    @node = parse_dir(node)
    start_line
  end

  def cat(item)
  end

  def connect(who)
    @who = who
    puts "connected to '#{who}'"
  end

  def exit(_)
    EM.stop
  end

  def initialize
    $stdout.sync = true
    @node = ''
    @who = ''
    start_line
  end

  def start_line
    puts "\n/#{@node}> "
  end

  def receive_line(line)
    return unless line =~ /(connect|exit|ls|cd|cat)\s?(.*)/i
    __send__ $1, $2
  end

  def parse_dir(list)
    return '' if list == '/'
    cur = @node.split('/')
    list.split('/').each { |dir| dir == '..' ? cur.pop : (cur << dir) }
    cur * '/'
  end
end

setup 'echo@jabber.local', 'echo'
pubsub_host 'pubsub.jabber.local'
when_ready { EM.open_keyboard CliHandler }
