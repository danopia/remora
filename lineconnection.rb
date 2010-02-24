require 'rubygems'
require 'eventmachine'
require 'socket'

module Remora
class LineConnection < EventMachine::Connection
  attr_accessor :port, :ip
  INSTANCES = []

  def initialize *args
    super()

    @buffer = ''
  end
	
  def post_init
    sleep 0.25
    @port, @ip = Socket.unpack_sockaddr_in get_peername
    $sock.puts "Connected to #{@ip}:#{@port}"
  end
		
  def send_line data
    $sock.puts "==> #{data}"
    send_data "#{data}\n"
  end

  def receive_data data
    @buffer += data
    while @buffer.include? "\n"
      line = @buffer.slice!(0, @buffer.index("\n")+1).chomp
      $sock.puts "<== #{line}"
      receive_line line
    end
  end
  
  def receive_line data
  end
  
  def unbind
    $sock.puts "connection closed to #{@ip}:#{@port}"
  end
end # class
end # module
