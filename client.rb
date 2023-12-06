#===============================================================================================================================
# !!!   client.rb  | Starts and manages a client instance that communicates with the server service.
#-----------------------------------------------------------------------------------------------------------------------------
# Version 0.6
# Date: 12/06/2023
#-----------------------------------------------------------------------------------------------------------------------------
require 'socket'

require './src/Configuration.rb'
require './src/SessionData.rb'

#===============================================================================================================================
# Creates a TCP client that communicates using string data with a TCP server.
class Client
  @@session = nil
  @@remote_ip = "localhost"
  @@local_ip = "localhost"

  #---------------------------------------------------------------------------------------------------------
  def initialize(server_ip = "localhost")
    username = ARGV.shift
    @@remote_ip, @@local_ip = Configuration.getSelfIP()
    tcpSocket = TCPSocket.new(server_ip, Configuration::PORT)
    @@session = SessionData.new(tcpSocket, username)
    # send server a request to initialize the client's session data
    @@session.send_msg("#{username}")
  end

  #---------------------------------------------------------------------------------------------------------
  # This is a blocking function, it uses two threads to send/recieve data
  def connect()
    thread_sd = Thread.new { local_sendData() }
    thread_rfs = Thread.new { receive_from_server() }
    thread_sd.join()
    thread_rfs.join()
    close()
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop, read and print lines from server's connected socket
  def receive_from_server()
    while incoming_data = @@session.await_msg()
      session_start_time, username, message_string = incoming_data
      #puts("#{@@session.username.inspect} #{username.inspect}")
      if @@session.username == username
        puts("(me)> #{message_string}")
      else
        puts("(#{username})> #{message_string}")
      end
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # local updates Loop, send client data to server for other clients
  def local_sendData()
    loop do
      text_to_send = gets.chomp()
      @@session.send_msg(text_to_send)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Close socket when done
  def close()
    @@session.close()
  end
end

#===============================================================================================================================
# Construct a new client and start a connection with server.
client = Client.new()
client.connect()
