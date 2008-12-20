%w[rubygems lib/blather drb/drb].each { |r| require r }

setup 'drb_client@jabber.local', 'drb_client'

handle :ready do
  DRb.start_service 'druby://localhost:99843', self
end
