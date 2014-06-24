require 'blather/client/dsl'

module MUC
  extend Blather::DSL
  when_ready do
    room = 'room_name'
    nickname = 'NickName'
    puts "Connected ! send messages to #{jid.stripped}."
    join room, nickname
  end

  message :groupchat?, :body do |m|
    unless m.delay || m.from == jid.stripped
      echo = Blather::Stanza::Message.new
      echo.to = room
      echo.body = m.body
      echo.type = 'groupchat'
      client.write echo
    end
  end
end
MUC.setup 'username', 'password'
EM.run { MUC.run }
