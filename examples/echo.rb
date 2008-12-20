%w[rubygems lib/blather].each { |r| require r }

setup 'echo@jabber.local', 'echo'

# Auto approve subscription requests
handle :subscription do |s|
  write(s.approve!) if s.request?
end

# Echo back what was said
handle :message do |m|
  write(m.reply) if m.chat?
end
