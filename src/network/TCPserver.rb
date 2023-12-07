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

    if Configuration::DEBUG
      puts("Server is now accepting new clients at addresses:"+
        "\n\tRemote: #{@@remote_ip}:#{Configuration::PORT}"+
        "\n\tLAN: #{@@local_ip}:#{Configuration::PORT}"+
        "\n\tlocalhost:#{Configuration::PORT}"
      )
    end
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
    session_init_data = session.await_msg()
    creation_time, client_name, message = session_init_data
    duplicate_user = false
    # prevent same usernames between multiple clients
    if find_client(client_name)
      outgoing_data = @@server_session.package_data("ERROR: The name '#{client_name}' is already in use.")
      session.send_msg(outgoing_data, false)
      duplicate_user = true
      if parent_window
        message = "WARN: Duplicate user '#{client_name}' tried to join."
        parent_window.send_data_into_state(message)
      end
    else
      # watch the client session for incoming data
      session.username = client_name
      outgoing_data = @@server_session.package_data("Hello #{client_name}! #{@@client_sessions.count} clients.")
      session.send_msg(outgoing_data, false)
      puts("sending welcome to client session: #{session.username}")
      outgoing_data = @@server_session.package_data("#{client_name} joined! #{@@client_sessions.count} clients.")
      announce_to_everyone(outgoing_data, [session.username], parent_window)
      # while connection remains open, read sent information
      while incoming_data = session.await_msg(false)
        announce_to_everyone(incoming_data, [], parent_window)
      end
    end
    # when the connection is no longer open or closed manually, dispose of the client
    session.close()
    unless duplicate_user
      outgoing_data = @@server_session.package_data("#{session.username} left!")
      announce_to_everyone(outgoing_data, [], parent_window)
    else
      outgoing_data = @@server_session.package_data("Duplicate user '#{client_name}' rejected!")
      announce_to_everyone(outgoing_data, [], parent_window)
    end
    @@client_sessions.delete(session)
  end
  
  #---------------------------------------------------------------------------------------------------------
  # Send information to all clients connected, unless excluded from the send.
  def announce_to_everyone(sessionData, exclusions = [], parent_window = nil)
    @@client_sessions.each {|session|
      unless exclusions.include?(session.username)
        session.send_msg(sessionData, false)
      end
    }
    # also anounce to server
    session_start_time, from_user, message = @@server_session.unpackage_data(sessionData)
    if parent_window
      parent_window.send_data_into_state([session_start_time, from_user, message])
    end
    puts("#{from_user}: #{message}") 
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
