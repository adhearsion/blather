%w[rubygems lib/blather/client].each { |r| require r }

setup 'echo@jabber.local/blather', 'echo'

handle :ready do
  puts "Echo server started for #{jid}"
end

# Auto approve subscription requests
handle :subscription do |s|
  write(s.approve!) if s.request?
end

# Echo back what was said
handle :message do |m|
  write(m.reply) if m.chat? && m.body
end
