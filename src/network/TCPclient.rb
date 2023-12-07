#===============================================================================================================================
# !!!   TCPclient.rb  |  Creates a TCP client that communicates using string data with a TCP server.
#===============================================================================================================================
class TCPclient
  @@tcpSocket = nil
  @@client_session = nil
  @@remote_ip = "localhost"
  @@local_ip = "localhost"

  attr_reader :error
  #---------------------------------------------------------------------------------------------------------
  def initialize(server_ip = "localhost")
    @error = nil
    @@remote_ip, @@local_ip = Configuration.getSelfIP()
    begin
      @@tcpSocket = TCPSocket.new(server_ip, Configuration::PORT)
    rescue => error
      case error
      when Errno::ECONNREFUSED
        @error = "WARN: TCPclient reporting server connection refused."
      else
        @error = error
      end
      puts(@error)
    end
    
    if Configuration::DEBUG
      puts("Client are addresses:"+
        "\n\tRemote: #{@@remote_ip}:#{Configuration::PORT}"+
        "\n\tLAN: #{@@local_ip}:#{Configuration::PORT}"+
        "\n\tlocalhost:#{Configuration::PORT}"
      )
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Send server a request to initialize the client's session data.
  def start_session(username = "")
    return if @error
    @@client_session = TCPSessionData.new(@@tcpSocket, username)
    @@client_session.send_msg("#{username}")
  end

  #---------------------------------------------------------------------------------------------------------
  def session()
    return @@client_session
  end

  #---------------------------------------------------------------------------------------------------------
  # This is a blocking function, it uses two threads to send/recieve data.
  def connect(parent_window = nil)
    if parent_window.nil?
      thread_sd = Thread.new { local_sendData() } 
    end
    thread_rfs = Thread.new { receive_from_server(parent_window) }
    thread_sd.join() if parent_window.nil?
    thread_rfs.join() 
    shutdown() unless parent_window.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop, read and print lines from server's connected socket.
  def receive_from_server(parent_window = nil)
    return unless @error.nil?
    while incoming_data_package = @@client_session.await_msg()
      time_stmp, from_user, data_mode, data = incoming_data_package.to_a()
      #puts("#{@@session.username.inspect} #{from_user.inspect}")
      if Configuration::CLI_MODE
        if @@client_session.username == from_user
          puts("(me)> #{data}")
        else
          puts("(#{from_user})> #{data}")
        end
      elsif parent_window
        parent_window.send_data_into_state(incoming_data_package)
      else
        puts("ERROR: TCPclient recieved data from the server but has no way to display it.")
      end
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Local updates Loop, send client data to server for other clients. * CLI mode only
  def local_sendData()
    loop do
      text_to_send = gets.chomp()
      @@client_session.send_msg(text_to_send)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def send_data(string = "")
    return if @error
    @@client_session.send_msg(string.chomp())
  end

  #---------------------------------------------------------------------------------------------------------
  # Gracefully shutdown the client and close the sockets.
  def shutdown()
    @@client_session.close() unless @@client_session.nil?
    @@client_session = nil
    @@tcpSocket = nil # TCPSessionData closes the socket
  end
end
