require 'colorize'
require "socket"
class Client
  def initialize(server)
    @server = server
    @request = nil
    @response = nil
    listen
    send
    @request.join
    @response.join
  end

  def send
    @request = Thread.new do
      loop { # write as much as you want
        msg = $stdin.gets.chomp
        @server.puts msg
      }
    end
  end

  def listen 
    @response = Thread.new do
      loop { # listen for ever
        input = @server.gets.chomp
        puts "#{input}".colorize(:green)
      }
    end
  end
end

server = TCPSocket.open('localhost', 3000)
Client.new server
