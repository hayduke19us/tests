require "socket"
require "Pathname"
require "json"

class Server
  attr_reader :connections, :server, :log_path, :log
  def initialize(ip, port)
    @server = TCPServer.open ip, port
    @connections  = Hash.new
    @rooms = Hash.new
    @clients = Hash.new
    @connections[:server] = @server
    @connections[:rooms] = @rooms
    @connections[:clients] = @clients
    @log_path = File.dirname(__FILE__) + 'log.json'
  end

  def run
    loop {
      Thread.start(self.server.accept) do | client |
        client.puts "What is your user name"
        nick_name = client.gets.chomp.to_sym

        self.connections[:clients].each do |other_name, other_client|
          if nick_name == other_name || client == other_client
            client.puts "This username already exist"
            Thread.kill self
          end
        end

        puts "#{nick_name} #{client}"
        self.connections[:clients][nick_name] = client

        client.puts "Connection established, Thank you for joining! Happy chatting"

        begin 
          self.log = {"#{nick_name.to_sym}" => Time.now}
          puts "Written"
        rescue => e
          puts "something went wrong #{e}"
        end

        self.listen_user_messages nick_name, client
      end
    }
  end

  def listen_user_messages nick_name, client
    loop {
      msg = client.gets.chomp
      if commands?(msg, client, nick_name)
        client.puts "As you command"
      else
        self.send_global_msg(msg, nick_name) if self.connections?
      end
    }
  end

  def connections?
    self.connections[:clients].count > 1
  end

  def send_global_msg msg, nick_name
    self.connections[:clients].each do |handle, other_client|
      unless handle == nick_name
        other_client.puts "#{nick_name.to_s}: #{msg}"
        self.log = { "#{nick_name.to_sym}" => msg }
      end
    end
  end

  def commands? input, client, nickname
    begin 
      if input == 'ls'
        client.puts "Online"
        client.puts  '=-=-=-=--=-=-='
        client.puts self.connections[:clients]
        true
      elsif input.match(/\Ahist/)
        client.puts self.get_history(nickname)
        true
      end
    rescue => e
      puts "something went wrong #{e}"
    end
  end

  def get_history nickname
    begin
      data = File.open(self.log_path, 'r').read
      hash = JSON.parse data
      hash.select(&nickname.to_sym)
    rescue => e
      puts "Something went wrong #{e}"
    end
  end

  def log=(msg)
    File.open self.log_path, 'a' do |f|
      f.write JSON.pretty_generate(msg)
    end
  end
end
# (ip, port) in each machine "localhost" = 127.0.0.1
server = Server.new("localhost", 3000) 
server.run
