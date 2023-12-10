#===============================================================================================================================
# !!!   TCPserver.rb  | Creates a TCP server that accepts string data and manages multiple clients.
#===============================================================================================================================
class TCPserver
  FAKE_LATENCY = false

  @@client_sessions = []
  @@server_session = nil
  @@tcpSocket = nil
  @@remote_ip = "localhost"
  @@local_ip = "localhost"
  @@parent_window = nil

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
    Logger.info("TCPserver", "Server is now accepting new clients at addresses:"+
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
  def session_thread_handle(client_session)
    # string data sent first is the client's session information
    session_init_data = client_session.await_data_msg()
    Logger.debug("TCPserver", "New client: (#{session_init_data.inspect})")
    creation_time, null_client_id, server_time, package_mode, requested_name = session_init_data.to_a()
    duplicate_user = nil
    # client names/ids should not be raw bytes, so enforce some encoding limitations for the string requested
    requested_name = requested_name.encode(Encoding::ASCII, undef: :replace, invalid: :replace, replace: "")
    # prevent same usernames between multiple clients
    if find_client(requested_name)
      duplicate_user = requested_name
      send_client_a_msg(client_session, "REUSED: Name '#{duplicate_user}' is already in use.")
      Logger.warn("TCPServer", "Duplicate user '#{duplicate_user}' tried to join.")
    else
      # welcome the new user client session and inform others of their arrival
      client_session.username = requested_name
      Logger.debug("TCPserver", "Sending a server welcome to client session id: (#{client_session.username})")
      send_client_a_msg(client_session, "Hello #{client_session.username}! #{@@client_sessions.count} clients.")
      puts("Check name (#{client_session.inspect})")
      send_clients_a_msg("#{client_session.username} joined! #{@@client_sessions.count} clients.", [client_session.username])
      # while client connection remains open, recieve data from them, proccess it and notify other clients
      while incoming_data_byteString = client_session.await_data_msg()
        case incoming_data_byteString
        when TCPSessionData::Package
          # to make things more managable, the byte string data is expanded into a class Object
          # this data can be verified if configured correctly to add a layer of error netting
          # as well as additional featuring when handling the data with other Objects
          if incoming_data_byteString.has_error?
            Logger.warn("TCPServer", "Recieved a message from a client malformed. (#{incoming_data_byteString.inspect})")
            break if @drop_clients_on_package_error
          else
            incoming_data_byteString.set_server_time()
            send_bytes_to_everyone(incoming_data_byteString, [])
          end
        when String
          # if already a packaged byte string, it will get packed again as a String this time
          # Strings being sent are typically some form of message in a human readable state
          send_bytes_to_everyone(incoming_data_byteString, [])
          Logger.debug("TCPServer", "Is sending a raw String value. (#{incoming_data_byteString.inspect})")
        end
      end
    end
    # when the connection is no longer open or closed manually, dispose of the client
    client_session.close()
    if duplicate_user.nil?
      send_clients_a_msg("#{client_session.username} left!")
    else
      send_clients_a_msg("Duplicate username '#{duplicate_user}' client rejected!")
    end
    @@client_sessions.delete(client_session)
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a basic string to all the clients.
  def send_clients_a_msg(string_msg = "", exclusions = [])
    outgoing_data = @@server_session.package_data(string_msg)
    send_bytes_to_everyone(outgoing_data, exclusions)
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a basic string to a single client.
  def send_client_a_msg(client_session, string_msg = "")
    outgoing_data = @@server_session.package_data(string_msg)
    client_session.send_msg(outgoing_data, false)
  end
  
  #---------------------------------------------------------------------------------------------------------
  # Send information to all clients connected, unless excluded from the send.
  def send_bytes_to_everyone(sessionData_byteString, exclusions = [])
    Logger.debug("TCPserver", "Sending to subscribed clients object (#{sessionData_byteString.inspect})")
    # validate the data about to be sent
    case sessionData_byteString
    when String
      data_package = @@server_session.unpackage_data(sessionData_byteString)
      Logger.debug("TCPserver", "Unpacked string before sending to clients. (#{data_package.inspect})")
    when TCPSessionData::Package
      data_package = sessionData_byteString
    else
      Logger.error("TCPserver", "Can only send clients strings or known network packages.")
      return nil
    end
    if data_package.has_error?
      Logger.error("TCPserver", 
        "Can not send a byte message that has errors to clients."+
        "\n(#{sessionData_byteString.inspect})"+
        "\n(#{data_package.inspect})"
      )
      return nil
    end
    # calculate local server's client latency values
    data_package.calculate_latency()
    # inform all the clients currently connected
    @@client_sessions.each {|client_session|
      sleep(0.5) if TCPserver::FAKE_LATENCY # add artificial latency in seconds
      unless exclusions.include?(client_session.username)
        client_session.send_msg(sessionData_byteString, false)
      end
    }
    # CLI mode console prints
    if Configuration::CLI_MODE
      time_stmp, from_user, data_mode, data = data_package.to_a()
      puts("#{from_user}: #{data}") 
    else
      # display at local server GUI application
      @@parent_window.send_data_into_state(data_package) unless @@parent_window.nil?
    end
    Logger.info("TCPserver",
      "Echo to self what was sent."+
      "\nRaw: (#{sessionData_byteString.inspect})"+
      "\nPackage: (#{data_package.inspect})\n\n"
    )
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # This is a blocking function, it waits for a client to connect.
  def listen(parent_window = nil)
    @@parent_window = parent_window
    loop do
      begin
        break if @@tcpSocket.nil?
        new_client = @@tcpSocket.accept()
        new_session = TCPSessionData.new(new_client)
        @@client_sessions << new_session
        Thread.new {
          session_thread_handle(new_session)
        }
      rescue => error
        case error
        when IOError
          Logger.error("TCPserver", "IOError: (#{error})")
        else
          Logger.error("TCPserver", "Listening on socket failed.\n#{error.inspect}")
        end
        break
      end
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
