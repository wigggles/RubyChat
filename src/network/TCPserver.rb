#===============================================================================================================================
# !!!   TCPserver.rb  | Creates a TCP server that accepts string data and manages multiple clients.
#===============================================================================================================================
class TCPserver
  @@client_sessions = []
  @@server_session = nil
  @@tcpSocket = nil
  @@remote_ip = "localhost"
  @@local_ip = "localhost"

  #---------------------------------------------------------------------------------------------------------
  def initialize()
    @@client_sessions = []
    @@tcpSocket = TCPServer.new(Configuration::PORT)
    @@remote_ip, @@local_ip = Configuration.getSelfIP()
    @@server_session = TCPSessionData.new(@@tcpSocket, "ServerHost")
    # When network session packages are validated from a client, should the server kick clients when
    # the package data is found to be invalid?
    @drop_clients_on_package_error = false
    # print additional information about session status
    Logger.info("Server is now accepting new clients at addresses:"+
      "\n\tRemote: #{@@remote_ip}:#{Configuration::PORT}"+
      "\n\tLAN: #{@@local_ip}:#{Configuration::PORT}"+
      "\n\tlocalhost:#{Configuration::PORT}"
    )
  end

  #---------------------------------------------------------------------------------------------------------
  def session()
    return @@server_session
  end

  #---------------------------------------------------------------------------------------------------------
  def clients()
    return @@client_sessions
  end

  #---------------------------------------------------------------------------------------------------------
  def find_client(username ="")
    located = @@client_sessions.select { |client| client.username == username }
    return located[0] if located.length > 0
    return nil
  end

  #---------------------------------------------------------------------------------------------------------
  # What to do when a client sends information.
  def session_thread_handle(session, parent_window)
    # string data sent first is the client's session information
    session_init_data = session.await_data_msg()
    Logger.debug("TCPserver", "New client: (#{session_init_data.inspect})")
    creation_time, null_client_id, server_time, package_mode, requested_name = session_init_data.to_a()
    duplicate_user = nil
    # prevent same usernames between multiple clients
    if find_client(requested_name)
      outgoing_data = @@server_session.package_data("REUSED: Name '#{requested_name}' is already in use.")
      session.send_msg(outgoing_data, false)
      duplicate_user = requested_name
      Logger.warn("TCPServer", "Duplicate user '#{requested_name}' tried to join.")
    else
      # watch the client session for incoming data
      session.username = requested_name
      outgoing_data = @@server_session.package_data("Hello #{session.username}! #{@@client_sessions.count} clients.")
      session.send_msg(outgoing_data, false)
      Logger.debug("TCPserver", "Sending a server welcome to client session id: (#{session.username})")
      outgoing_data = @@server_session.package_data("#{session.username} joined! #{@@client_sessions.count} clients.")
      send_bytes_to_everyone(outgoing_data, [session.username], parent_window)
      # while connection remains open, read sent information and then forward it to clients
      while incoming_data_byteString = session.await_data_msg()
        case incoming_data_byteString
        when TCPSessionData::Package
            if incoming_data_byteString.has_valid_data?
              incoming_data_byteString.set_server_time()
              send_bytes_to_everyone(incoming_data_byteString, [], parent_window)
            else
              package_error = true
            end
        when String
          send_bytes_to_everyone(incoming_data_byteString, [], parent_window)
        else
          package_error = true
        end
        if package_error
          Logger.warn("TCPServer", "Recieved a message from a client malformed. (#{incoming_data_byteString.inspect})")
          # stop listening to that client and kick them from the server
          break if @drop_clients_on_package_error
        end
      end
    end
    # when the connection is no longer open or closed manually, dispose of the client
    session.close()
    if duplicate_user.nil?
      outgoing_data = @@server_session.package_data("#{session.username} left!")
      send_bytes_to_everyone(outgoing_data, [], parent_window)
    else
      outgoing_data = @@server_session.package_data("Duplicate user '#{requested_name}' rejected!")
      send_bytes_to_everyone(outgoing_data, [], parent_window)
    end
    @@client_sessions.delete(session)
  end
  
  #---------------------------------------------------------------------------------------------------------
  # Send information to all clients connected, unless excluded from the send.
  def send_bytes_to_everyone(sessionData_byteString, exclusions = [], parent_window = nil)
    Logger.debug("TCPserver", "Sending to subscribed clients object (#{sessionData_byteString.inspect})")
    @@client_sessions.each {|session|
      #sleep(0.5) # add artificial latency
      unless exclusions.include?(session.username)
        session.send_msg(sessionData_byteString, false)
      end
    }
    # also display at local server interface application
    data_package = @@server_session.unpackage_data(sessionData_byteString)
    data_package.calculate_latency() # calculate local server's client latency values
    parent_window.send_data_into_state(data_package) if parent_window
    Logger.info("TCPserver", 
      "Echo to self what was sent."+
      "\n#{sessionData_byteString.inspect}"+
      "\n(#{data_package.inspect})\n\n"
    )
    # CLI mode prints
    return unless Configuration::CLI_MODE
    time_stmp, from_user, data_mode, data = data_package.to_a()
    puts("#{from_user}: #{data}") 
  end

  #---------------------------------------------------------------------------------------------------------
  # This is a blocking function, it waits for a client to connect.
  def listen(parent_window = nil)
    loop do
      new_client = @@tcpSocket.accept()
      new_session = TCPSessionData.new(new_client)
      @@client_sessions << new_session
      Thread.new {
        session_thread_handle(new_session, parent_window)
      }
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Gracefully shutdown the server and close the sockets.
  def shutdown()
    @@server_session.close() unless @@server_session.nil?
    @@client_sessions = []
    @@server_session = nil
    @@tcpSocket = nil # TCPSessionData closes the socket
  end
end
