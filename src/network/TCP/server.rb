#===============================================================================================================================
# !!!   TCPserver.rb  | Creates a TCP server that accepts string data and manages multiple clients.
#===============================================================================================================================
class TCPserver
  FAKE_LATENCY = false

  @@server_session = nil
  @@tcpSocket = nil
  @@remote_ip = "localhost"
  @@local_ip = "localhost"
  @@parent_window = nil

  #---------------------------------------------------------------------------------------------------------
  def initialize()
    @@tcpSocket = TCPServer.new(Configuration::PORT)
    @@remote_ip, @@local_ip = Configuration.getSelfIP()
    @@server_session = TCPsession.new(@@tcpSocket, "ServerHost")
    # When network session packages are validated from a client, should the server kick clients when
    # the package data is found to be invalid?
    @drop_clients_on_package_error = false
    # print additional information about session status
    Logger.info("TCPserver", "Server is now accepting new clients at addresses:"+
      "\n\tRemote: #{@@remote_ip}:#{Configuration::PORT}"+
      "\n\tLAN: #{@@local_ip}:#{Configuration::PORT}"+
      "\n\tlocalhost:#{Configuration::PORT}",
      tags: [:Network]
    )
  end

  #---------------------------------------------------------------------------------------------------------
  def session()
    return @@server_session
  end

  #---------------------------------------------------------------------------------------------------------
  def client_pool()
    return nil if session.nil?
    return session.get_client_pool()
  end

  #---------------------------------------------------------------------------------------------------------
  def find_client(by: :ref_id, search_term: "")
    located = client_pool.find_client(by: by, search_term: search_term)
    return located
  end

  #---------------------------------------------------------------------------------------------------------
  # How to handle new client introductions with the server session.
  def handle_handshake(client_session, requested_name)
    # client names/ids should not be raw bytes, so enforce some encoding limitations for the string requested
    requested_name = requested_name.encode(Encoding::ASCII, undef: :replace, invalid: :replace, replace: "")
    # check if new client is attempting to duplicate another
    duplicate_user = find_client(by: :username, search_term: requested_name)
    if duplicate_user
      send_client_a_msg(client_session, "REUSED: Name '#{duplicate_user}' is already in use.")
      Logger.warn("TCPServer", "Duplicate user '#{duplicate_user}' tried to join.",
        tags: [:Network, :Client]
      )
      return duplicate_user
    end
    # welcome the new user client session and inform others of their arrival
    description = client_pool.add_new(client_session)
    if description
      description.set_name(requested_name)
    else
      Logger.error("TCPserver", "New client already exists in the pool, did not add Client again."+
        "\nswimmers: (#{client_pool.count()})"+
        "\nskipped cannonball: (#{client_session.inspect})",
        tags: [:Network, :Client]
      )
      return nil
    end
    sync_server_clients()
    Logger.debug("TCPserver", "New client description: (#{description.inspect})",
      tags: [:Network, :Client]
    )
    send_client_a_msg(client_session, "Hello #{description.username}! #{client_pool.count()} clients.")
    puts("Check name (#{client_session.inspect})")
    send_clients_a_msg("#{description.username} joined! #{client_pool.count()} clients.", [description.ref_id])
    # report that the user requested is unique
    return nil
  end

  #---------------------------------------------------------------------------------------------------------
  # How to say goodbye to a client and inform subscribed watchers.
  def handle_goodbye(client_session, duplicate_user)
    # when the connection is no longer open or closed manually, dispose of the client
    client_session.close()
    if duplicate_user.nil?
      client_description = find_client(by: :ref_id, search_term: client_session.description.ref_id)
      unless client_description
        send_clients_a_msg("#{client_description.username} left!")
      else
        Logger.warn("TCPServer", "User left with out ever having a description attached. (#{client_session.inspect})",
          tags: [:Network]
        )
      end
    else
      send_clients_a_msg("Duplicate username '#{duplicate_user}' client rejected!")
    end
    client_pool.delete(client_session.description.ref_id)
  end

  #---------------------------------------------------------------------------------------------------------
  # What to do when a client sends information.
  def session_thread_handle(client_session)
    # string data sent first is the client's session information
    session_init_data = client_session.await_data_msg()
    creation_time, null_client_id, server_time, package_mode, requested_name = session_init_data.to_a()
    duplicate_user = nil
    # prevent same usernames between multiple clients
    duplicate_user = handle_handshake(client_session, requested_name)
    unless duplicate_user
      # while client connection remains open, recieve data from them, proccess it and notify other clients
      while incoming_data_byteString = client_session.await_data_msg()
        case incoming_data_byteString
        when TCPsession::Package
          # to make things more managable, the byte string data is expanded into a class Object
          # this data can be verified if configured correctly to add a layer of error netting
          # as well as additional featuring when handling the data with other Objects
          if incoming_data_byteString.has_error?
            Logger.warn("TCPServer", "Recieved a message from a client malformed. (#{incoming_data_byteString.inspect})",
              tags: [:Network]
            )
            break if @drop_clients_on_package_error
          else
            incoming_data_byteString.set_server_time()
            send_bytes_to_everyone(incoming_data_byteString, [])
          end
        when String
          # if already a packaged byte string, it will get packed again as a String this time
          # Strings being sent are typically some form of message in a human readable state
          send_bytes_to_everyone(incoming_data_byteString, [])
          Logger.debug("TCPServer", "Is sending a raw String value. (#{incoming_data_byteString.inspect})",
            tags: [:Network]
          )
        end
      end
    end
    handle_goodbye(client_session, duplicate_user)
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a basic String message to all the subscribed clients.
  def send_clients_a_msg(string_msg = "", exclusions = [])
    outgoing_data = @@server_session.package_data(string_msg)
    send_bytes_to_everyone(outgoing_data, exclusions)
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a basic String message to a single client.
  def send_client_a_msg(client_session, string_msg = "")
    outgoing_data = @@server_session.package_data(string_msg)
    client_session.send_msg(outgoing_data, pack_data: false)
  end

  #---------------------------------------------------------------------------------------------------------
  # Sync with clients user 'ref_id's to description data for their local use.
  def sync_server_clients()
    package = @@server_session.empty_data_package()
    array_package = client_pool.pack_array_to_send()
    outgoing_data = package.get_packed_string(TCPsession::Package::DATAMODE::CLIENT_SYNC, [ClientPool::DATAMODE::ALL_CLIENTS, array_package])
    Logger.debug("TCPserver", "Server is sending a request to sync clients:"+
      "\nPool: (#{array_package.inspect})"+
      "\nData: (#{package.data.inspect})"+
      "\nPackage: (#{outgoing_data.inspect})",
      tags: [:Network, :Client]
    )
    send_bytes_to_everyone(outgoing_data, [], true)
  end
  
  #---------------------------------------------------------------------------------------------------------
  # Send information to all clients connected, unless excluded from the send.
  def send_bytes_to_everyone(sessionData_byteString, exclusions = [], pre_packaged = false)
    Logger.debug("TCPserver", "Sending data to subscribed clients: (#{sessionData_byteString.inspect})")
    # validate the data about to be sent
    case sessionData_byteString
    when String
      data_package = @@server_session.unpackage_data(sessionData_byteString)
      Logger.info("TCPserver",
        "Unpacked string into package before forwarding to clients. (#{data_package.inspect})",
        tags: [:Network, :Package]
      )
    when TCPsession::Package
      data_package = sessionData_byteString
    else
      Logger.error("TCPserver", 
        "Can only send clients strings or known network packages. NOT:(#{sessionData_byteString.inspect})",
        tags: [:Network]
      )
      return nil
    end
    if data_package.has_error?
      Logger.error("TCPserver", 
        "Can not send a byte message that has errors to clients."+
        "\n(#{sessionData_byteString.inspect})"+
        "\n(#{data_package.inspect})",
        tags: [:Network, :Package]
      )
      return nil
    end
    # calculate local server's client latency values
    data_package.calculate_latency()
    # inform all the clients currently connected
    client_pool.each {|client_description|
      sleep(0.5) if TCPserver::FAKE_LATENCY # add artificial latency in seconds
      unless exclusions.include?(client_description.ref_id)
        unless client_description.session_pointer.nil?
          next if session.is_self?(client_description.ref_id)
          client_description.session_pointer.send_msg(data_package, pack_data: false)
        else
          Logger.error("TCPserver", "When sending to client pool, a client did not have a session."+
            "\ndescription: (#{client_description.inspect})",
            tags: [:Network]
          )
        end
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
      "\nPackage: (#{data_package.inspect})\n\n",
      tags: [:Network]
    )
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # How a new client session arives and is added into the server's pool to be synced later with client swimmers.
  def handle_cannonball(client_socket)
    client_session = TCPsession.new(client_socket)
    Logger.info("TCPserver", "New client ref_id:(#{client_session.description.ref_id}) wants to swim in the pool."+
      "\nSession: (#{client_session.inspect})"+
      "\nsocket: (#{client_socket.inspect})",
      tags: [:Network, :Client]
    )
    # syncronize the client's local session's Client ref_id with what the server reports them as being localy to it.
    # this means the local ref_id the client generated will be thrown out, and a new ref_id for the Server's client pool
    # Client objects will be syncronized to that clients socket. If the server recieves a message from a client whos
    # ref_id isn't in the pool, it can check for that and many more kinds of things.
    Logger.debug("TCPserver", "Reporting to client splash ref_id:(#{client_session.description.ref_id}).",
      tags: [:Network, :Client]
    )
    send_client_a_msg(client_session, "#{client_session.description.ref_id}")
    return client_session
  end

  #---------------------------------------------------------------------------------------------------------
  # This is a blocking function, it waits for a client to connect.
  def listen(parent_window = nil)
    @@parent_window = parent_window
    loop do
      begin
        break if @@tcpSocket.nil?
        new_client_socket = @@tcpSocket.accept()
        Thread.new {
          session_thread_handle(handle_cannonball(new_client_socket))
        }
      rescue => error
        case error
        when IOError
          Logger.error("TCPserver", "IOError: (#{error})")
        else
          Logger.error("TCPserver", "Listening on socket failed.\n#{error.inspect}",
            tags: [:Network]
          )
        end
        break
      end
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Gracefully shutdown the server and close the sockets.
  def shutdown()
    @@server_session.close() unless @@server_session.nil?
    @@server_session = nil
    @@tcpSocket = nil # TCPsession closes the socket
  end
end
