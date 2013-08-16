require 'socket'

class Tube
  def initialize(port)
    @server = TCPServer.new(port)
  end
  
  def start
    loop do
      @socket = @server.accept
      connection = Connection.new
      connection.process
    end
  end
end

class Connection
  def initialize(socket)
    @socket = socket
  end
  
  def process
    data = @socket.readpartial(1024)
    puts data
  end

  def send_response
    @socket.write "HTTP/1.1  200 OK\r\n"
    @socket.write "\r\n"
    @socket.write "hello andy \r\n"
    close
  end

  def close
    @socket.write "HTTP/1.1  200 OK\r\n"
  end
end
server = Tube.new(3003)
server.start
