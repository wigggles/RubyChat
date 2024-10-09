#=====================================================================================================================
# !!!   TCPclient.rb  |  Creates a TCP client that communicates using string data with a TCP server.
#=====================================================================================================================
class TCPclient
  attr_reader :error, :connected

  #---------------------------------------------------------------------------------------------------------
  def initialize(server_ip = 'localhost')
    @error = nil
    @connected = false
    @client_session = nil
    @remote_ip, @local_ip = Configuration.getSelfIP
    begin
      @tcpSocket = TCPSocket.new(server_ip, Configuration::PORT)
    rescue StandardError => e
      @error = true
      case e
      when Errno::ECONNREFUSED
        Logger.warn('TCPclient', 'Reporting server connection refused.',
                    tags: [:Network])
      else
        Logger.error('TCPclient', "#{e}",
                     tags: [:Network])
      end
    end
    # print additional information about session status
    Logger.info('TCPclient', 'Client is at addresses:' +
      "\n\tRemote: #{@remote_ip}:#{Configuration::PORT}" +
      "\n\tLAN: #{@local_ip}:#{Configuration::PORT}" +
      "\n\tlocalhost:#{Configuration::PORT}",
                tags: [:Network])
  end

  #---------------------------------------------------------------------------------------------------------
  # Send server a request to initialize the client's session data.
  def start_session(username = '')
    return if @error

    @client_session = TCPsession.new(@tcpSocket, username)
    @client_session.send_msg("#{username}")
  end

  #---------------------------------------------------------------------------------------------------------
  def session
    @client_session
  end

  #---------------------------------------------------------------------------------------------------------
  # When the local client first makes contact with the server, the server will report back some information.
  def server_pool_cannonball
    splash = @client_session.await_data_msg
    # locally verify the reporting splash from the server's Client pool
    case splash
    when TCPsession::Package
      report = splash.data.to_s
    when String
      report = splash.chomp.to_s
    end
    Logger.debug('TCPclient', "Server cannonball:(#{report.inspect})",
                 tags: %i[Network Client])
    session.description.set_ref_id(report)
  end

  #---------------------------------------------------------------------------------------------------------
  # This is a blocking function, it uses two threads to send/receive data.
  def connect(report_to: nil)
    # attempt to start a new thread, but catch exceptions thrown if anything dies along the way
    begin
      thread_sd = Thread.new { local_sendData } if report_to.nil?
      # jump on in, see what the server says about it
      thread_rfs = Thread.new do
        @connected = !server_pool_cannonball.nil?
        while @connected # 'has an id from server'
          receive_from_server(report_to: report_to)
          @connected = !@client_session.closed?
        end
      end
      thread_sd.join if report_to.nil?
      thread_rfs.join
    rescue StandardError => e
      Logger.error('TCPclient', 'Listening Thread died, connection with remote closed.' +
        "\n(#{e.inspect})",
                   tags: [:Network])
      report_to = nil
    end
    shutdown unless report_to.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop, read and print lines from server's connected socket.
  def receive_from_server(report_to: nil)
    return unless @error.nil?

    incoming_data_package = @client_session.await_data_msg
    unless incoming_data_package.nil?
      incoming_data_package.calculate_latency # calculate client server latency
      _, from_user_id, _, _, data = incoming_data_package.to_a
      Logger.debug('TCPclient', "received server package from: (#{from_user_id.inspect})",
                   tags: %i[Network Package])
      if Configuration::CLI_MODE
        if @@client_session.is_self?(from_user_id)
          puts("(me)> #{data}")
        else
          puts("(#{from_user_id})> #{data}")
        end
      elsif report_to
        report_to.send_data_into_state(incoming_data_package)
      else
        Logger.error('TCPclient', 'received data from the server but has no way to display it.',
                     tags: [:Network])
      end
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Local updates Loop, send client data to server for other clients. * CLI mode only
  def local_sendData
    loop do
      text_to_send = gets.chomp
      @client_session.send_msg(text_to_send)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def send_data(data)
    return if @error

    case data
    when String
      Logger.debug('TCPclient', 'Sending String data.',
                   tags: [:Network])
      data = data.chomp
    when TCPsession::Package
      Logger.debug('TCPclient', 'Sending TCPsession::Package data.',
                   tags: %i[Network Package])
      data.set_creation_time
    else
      Logger.error('TCPclient', "Attempting to send data type it doesn't recognize. (#{data.class})",
                   tags: [:Network])
      return nil
    end
    @client_session.send_msg(data)
  end

  #---------------------------------------------------------------------------------------------------------
  # Gracefully shutdown the client and close the sockets.
  def shutdown
    @client_session.close unless @client_session.nil?
    @client_session = nil
    @tcpSocket = nil # TCPsession closes the socket
  end
end
