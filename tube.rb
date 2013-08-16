require 'socket'
require 'http/parser'
require 'pry'

class Tube
  def initialize(port, app)
    @app = app
    @server = TCPServer.new(port)
  end

  def prefork(workers=3)
    workers.times do
     fork do 
       puts "Fork Pid is #{Process.pid}"
       start
     end
    end
    Process.waitall
  end
  
  def start
    loop do
      @socket = @server.accept
      Thread.new do
        b = Time.now
        puts 'begin....'
        puts b
        connection = Connection.new(@socket, @app)
        connection.process
        e = Time.now
        puts "This request cost #{e-b}"
        puts e
      end
    end
  end

  class Connection
    def initialize(socket, app)
      @socket = socket
      @app = app
      @parser = Http::Parser.new(self)
    end
    
    def process
      until @socket.closed? || @socket.eof?
        data = @socket.readpartial(1024)
        @parser << data
      end
    end

    def on_message_complete
      puts "#{@parser.http_method}: #{@parser.request_path}"
      puts " " + @parser.headers.inspect
      
      env = {}
      @parser.headers.each_pair do |name, value|
        name = "HTTP_" + name.upcase.tr("-", "_")
        env[name] = value
      end
      env["PATH_INFO"] = @parser.request_path
      env["REQUEST_METHOD"] = @parser.http_method
      env["rack.input"] = StringIO.new

      send_response(env)
    end

    def send_response(env)
      status, header, body = @app.call(env)

      @socket.write "HTTP/1.1  200 OK\r\n"
      @socket.write "\r\n"
      body.each do |chunk|
        @socket.write chunk
      end
      body.close if body.respond_to? :close
      close
    end

    def close
      @socket.write "HTTP/1.1  200 OK\r\n"
      @socket.close
    end
  end

  class Builder
    attr_reader :app

    def run(app)
      @app = app
    end

    def self.parse_file(file)
      content = File.read(file)
      builder = self.new
      builder.instance_eval(content)
      builder.app
    end
  end
end
app = Tube::Builder.parse_file('config.ru')
server = Tube.new(3003, app)
server.prefork
