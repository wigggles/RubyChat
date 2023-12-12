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
      @error = true
      case error
      when Errno::ECONNREFUSED
        Logger.warn("TCPclient", "Reporting server connection refused.",
          tags: [:Network]
        )
      else
        Logger.error("TCPclient", "#{error}",
          tags: [:Network]
        )
      end
    end
    # print additional information about session status
    Logger.info("TCPclient", "Client is at addresses:"+
      "\n\tRemote: #{@@remote_ip}:#{Configuration::PORT}"+
      "\n\tLAN: #{@@local_ip}:#{Configuration::PORT}"+
      "\n\tlocalhost:#{Configuration::PORT}",
      tags: [:Network]
    )
  end

  #---------------------------------------------------------------------------------------------------------
  # Send server a request to initialize the client's session data.
  def start_session(username = "")
    return if @error
    @@client_session = TCPsession.new(@@tcpSocket, username)
    @@client_session.send_msg("#{username}")
  end

  #---------------------------------------------------------------------------------------------------------
  def session()
    return @@client_session
  end

  #---------------------------------------------------------------------------------------------------------
  # When the local client first makes contact with the server, the server will report back some information.
  def server_pool_cannonball()
    splash = @@client_session.await_data_msg()
    report = splash.data.slice(ClientPool::REF_BYTE_SIZE)[0]
    Logger.debug("TCPclient", "Server cannonball:(#{report.inspect})",
      tags: [:Network, :Client]
    )
  end

  #---------------------------------------------------------------------------------------------------------
  # This is a blocking function, it uses two threads to send/recieve data.
  def connect(parent_window = nil)
    if parent_window.nil?
      thread_sd = Thread.new { local_sendData() } 
    end
    thread_rfs = Thread.new { 
      server_pool_cannonball()
      receive_from_server(parent_window) 
    }
    thread_sd.join() if parent_window.nil?
    thread_rfs.join() 
    shutdown() unless parent_window.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop, read and print lines from server's connected socket.
  def receive_from_server(parent_window = nil)
    return unless @error.nil?
    while incoming_data_package = @@client_session.await_data_msg()
      incoming_data_package.calculate_latency() # calculate client server latency
      time_stmp, from_user_id, srvr_time_stmp, data_mode, data = incoming_data_package.to_a()
      Logger.debug("TCPclient", "Recieved server package from: (#{from_user_id.inspect})",
        tags: [:Network, :Package]
      )
      if Configuration::CLI_MODE
        if @@client_session.is_self?(from_user_id)
          puts("(me)> #{data}")
        else
          puts("(#{from_user_id})> #{data}")
        end
      elsif parent_window
        parent_window.send_data_into_state(incoming_data_package)
      else
        Logger.error("TCPclient", "Recieved data from the server but has no way to display it.",
          tags: [:Network]
        )
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
  def send_data(data)
    return if @error
    case data
    when String
      Logger.debug("TCPclient", "Sending String data.",
        tags: [:Network]
      )
      data = data.chomp()
    when TCPsession::Package
      Logger.debug("TCPclient", "Sending TCPsession::Package data.",
        tags: [:Network, :Package]
      )
      data.set_creation_time()
    else
      Logger.error("TCPclient", "Attempting to send data type it doesnt recognize. (#{data.class})",
        tags: [:Network]
      )
      return nil
    end
    @@client_session.send_msg(data)
  end

  #---------------------------------------------------------------------------------------------------------
  # Gracefully shutdown the client and close the sockets.
  def shutdown()
    @@client_session.close() unless @@client_session.nil?
    @@client_session = nil
    @@tcpSocket = nil # TCPsession closes the socket
  end
end
