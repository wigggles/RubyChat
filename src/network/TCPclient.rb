#===============================================================================================================================
# !!!   TCPclient.rb  |  Creates a TCP client that communicates using string data with a TCP server.
#===============================================================================================================================
class TCPclient
  @@tcpSocket = nil
  @@client_session = nil
  @@remote_ip = "localhost"
  @@local_ip = "localhost"

  #---------------------------------------------------------------------------------------------------------
  def initialize(server_ip = "localhost")
    @error = false
    @@remote_ip, @@local_ip = Configuration.getSelfIP()
    begin
      @@tcpSocket = TCPSocket.new(server_ip, Configuration::PORT)
    rescue => error
      case error
      when Errno::ECONNREFUSED
        puts("TCPclient reporting server connection refused.")
      else
        puts(error)
      end
      @error = true
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
  # Send server a request to initialize the client's session data
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
  # This is a blocking function, it uses two threads to send/recieve data
  def connect(parent_window = nil)
    if parent_window.nil?
      thread_sd = Thread.new { local_sendData() } 
    end
    thread_rfs = Thread.new { receive_from_server(parent_window) }
    thread_sd.join() if parent_window.nil?
    thread_rfs.join() 
    close() unless parent_window.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop, read and print lines from server's connected socket
  def receive_from_server(parent_window = nil)
    return if @error
    while incoming_data = @@client_session.await_msg()
      session_start_time, from_user, message = incoming_data
      #puts("#{@@session.username.inspect} #{from_user.inspect}")
      if @@client_session.username == from_user
        puts("(me)> #{message}")
      else
        puts("(#{from_user})> #{message}")
      end
      if parent_window
        parent_window.send_data_into_state([session_start_time, from_user, message])
      end
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # local updates Loop, send client data to server for other clients
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
  # Close socket when done
  def close()
    @@client_session.close() unless @@client_session.nil?
  end
end
