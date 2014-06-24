require 'blather/client/dsl'

module MUC
	extend Blather::DSL
	when_ready do
         room = 'hipchat_room'
         nickname = 'NickName'
		 puts "Connected ! send messages to #{jid.stripped}."
		 join room, nickname
	end

	message :groupchat?, :body do |m|
             #puts m.from #uncomment this to obtain your username
             unless m.delay or m.from == 'your_username' #putting your username here prevents responding to yourself
                 echo = Blather::Stanza::Message.new
                 echo.to = room
                 echo.body = m.body
                 echo.type = 'groupchat'
                 client.write echo
             end
	end
end
username = 'chat_username'
password = 'chat_password'
MUC.setup username,password
EM.run { MUC.run }
