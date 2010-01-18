#!/usr/bin/env ruby

require 'blather'

trap(:INT) { EM.stop }
trap(:TERM) { EM.stop }
EM.run do
  Blather::Stream::Client.start(Class.new {
    attr_accessor :jid

    def post_init(stream, jid = nil)
      @stream = stream
      self.jid = jid

      @stream.send_data Blather::Stanza::Presence::Status.new
      puts "Stream started!"
    end

    def receive_data(stanza)
      @stream.send_data stanza.reply!
    end

    def unbind
      puts "Stream ended!"
    end
  }.new, 'echo@jabber.local', 'echo')
end
