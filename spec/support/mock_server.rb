# encoding: utf-8

class MockServer
  def receive_data(data)
  end
end

class ServerMock
  include Celluloid::IO

  def initialize(host, port, mock_target = MockServer.new)
    Logger.debug "Starting echo server on #{host}:#{port}"
    @server = TCPServer.new host, port
    @mock_target = mock_target
    @clients = []
    run!
  end

  def shutdown
    Logger.debug "ServerMock shutting down"
    @clients.each do |client|
      close_quietly client
    end
    close_quietly @server
  end

  def run
    after(0.5) do
      Logger.debug "Server terminating"
      terminate
    end
    loop { handle_connection! @server.accept }
  rescue IOError
  end

  def handle_connection(socket)
    @clients << socket
    _, port, host = socket.peeraddr
    Logger.debug "Received connection from #{host}:#{port}"
    loop { receive_data socket.readpartial(4096) }
  rescue IOError
  end

  def receive_data(data)
    Logger.debug "ServerMock receiving data: #{data}"
    @mock_target.receive_data data
  end

  def send_data(data)
    Logger.debug "Sending data to clients: #{data}"
    @clients.each { |client| client.write data }
  end

  private

  def close_quietly(socket)
    socket.close
  rescue IOError
  end
end
