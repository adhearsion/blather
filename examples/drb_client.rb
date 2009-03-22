%w[rubygems lib/blather/client drb/drb].each { |r| require r }

setup 'drb_client@jabber.local', 'drb_client'

when_ready { DRb.start_service 'druby://localhost:99843', self }
