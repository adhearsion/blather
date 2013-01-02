class MockServer; end

module ServerMock
  def receive_data(data)
    @server ||= MockServer.new
    @server.receive_data data, self
  end
end
