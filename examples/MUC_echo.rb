require 'blather/client/dsl'

module MUC
  extend Blather::DSL
  when_ready do
    puts "Connected ! send messages to #{jid.stripped}."
    join 'room_name', 'nick_name'
  end

  message :groupchat?, :body, proc { |m| m.from != jid.stripped }, delay: nil do |m|
      echo = Blather::Stanza::Message.new
      echo.to = room
      echo.body = m.body
      echo.type = 'groupchat'
      client.write echo
  end
end
MUC.setup 'username', 'password'
EM.run { MUC.run }
