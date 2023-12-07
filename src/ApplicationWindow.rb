#===============================================================================================================================
# !!!  ApplicationWindow.rb |  An interactive Gosu Window based chat GUI.
#===============================================================================================================================
require 'socket'
require 'gosu'

require './src/internal/InputControls.rb'

require './src/network/TCPSessionData.rb'
require './src/network/TCPserver.rb'
require './src/network/TCPclient.rb'

require './src/GUI/Components/TextField.rb'
require './src/GUI/Components/ConsoleBox.rb'
require './src/GUI/MainState.rb'

#===============================================================================================================================
class ApplicationWindow < Gosu::Window
  @@application_state = nil
  @@controls = nil
  @@font = nil
  @@service_mode = nil || :offline

  #---------------------------------------------------------------------------------------------------------
  # Construct server and listen for/to clients
  def initialize(is_server = false)
    @initialized_later = 20
    GC.start()
    super(Configuration::SCREEN_WIDTH, Configuration::SCREEN_HEIGHT, Configuration::FULLSCREEN)
    @@font = Gosu::Font.new(self, nil, 24)
    @@controls = InputControls.new(self)
    # create a new session socket manager
    @is_server = is_server
    if is_server
      @@service_mode = :tcp_server
      start_server_service()
    else
      @username = ARGV[0] || "GosuGUI_01"
      @@service_mode = :tcp_client
    end
    # anounce to gui that the server is listening
    set_app_state(MainState.new(self))
    case @@service_mode
    when :tcp_server
      send_data_into_state("Server started, listening...")
    when :tcp_client
      #nothing
    else
      send_data_into_state("ERROR: unable to open socket. (#{@@service_mode})")
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def start_server_service()
    case @@service_mode
    when :tcp_server
      @server = TCPserver.new()
      Thread.new {
        @server.listen(self)
      }
    else
      puts("ERROR: Unkown socket server type. (#{@@service_mode})")
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def start_client_service()
    case @@service_mode
    when :tcp_client
      Thread.new { 
        @client = TCPclient.new("localhost")
        if @client.error.nil?
          @client.start_session(@username)
          start_client_session()
          @client.connect(self)
        else
          #puts("ERROR: ApplicationWindow failed to start client session. (#{@client.error})")
          send_data_into_state(@client.error.to_s)
        end
      }
    else
      puts("ERROR: Unkown socket client type. (#{@@service_mode})")
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def start_client_session()
    unless @client.nil?
      if @client.session.nil?
        send_data_into_state("Server not found.")
      else
        send_data_into_state("Client touched server.")
      end
    else
      send_data_into_state("Can not start session.")
    end
  end

  #---------------------------------------------------------------------------------------------------------
  #:D Called by Gosu::Window when a button was pressed, but was now released.
  def button_up(id)
    return if @@controls.nil?
    @@controls.button_up(id)
    super(id)
  end
  #---------------------------------------------------------------------------------------------------------
  #:D Called by Gosu::Window when a button has been pressed.
  def button_down(id)
    return if @@controls.nil?
    @@controls.button_down(id)
    super(id)
  end

  #---------------------------------------------------------------------------------------------------------
  def controls
    return @@controls
  end

  #---------------------------------------------------------------------------------------------------------
  def current_session()
    case @@service_mode
    when :tcp_server
      return nil if @server.nil?
      return @server.session
    when :tcp_client
      return nil if @client.nil?
      return @client.session
    else # :offline
      return nil
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def network_service()
    case @@service_mode
    when :tcp_server
      return @server
    when :tcp_client
      return @client
    else # :offline
      return nil
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Used to utilze the open session socket to send data.
  def send_socket_data(data)
    return nil if network_service().nil?
    return nil if current_session().nil?    
    case @@service_mode
    when :tcp_server
      case data
      when TCPSessionData::Package
        data_byte_string = data.get_packed_string()
      when String
        data_byte_string = current_session.package_data(data)
      else
        puts("ERROR: ApplicationWindow server attempting to send unkown data type. (#{data.class})")
        return nil
      end
      #puts("DEBUG: ApplicationWindow server sending data. (#{data.inspect})")
      return @server.send_bytes_to_everyone(data_byte_string, [], self)
    when :tcp_client
      #puts("DEBUG: ApplicationWindow client sending data. (#{data.inspect})")
      return @client.send_data(data)
    else # :offline
      return nil
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Create a new data package for sending information.
  def getNew_session_package()
    return nil if network_service().nil?
    return nil if current_session().nil?
    return current_session.empty_data_package()
  end

  #---------------------------------------------------------------------------------------------------------
  def get_service_mode()
    return @@service_mode
  end

  #---------------------------------------------------------------------------------------------------------
  def resizable?
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  def needs_cursor?
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  def close()
    puts("WARN: Closing application window.")
    shutdown_network()
    super()
  end

  #---------------------------------------------------------------------------------------------------------
  def shutdown_network()
    service = network_service()
    unless service.nil?
      # inform the clients the server is shutting down
      if @is_server
        session = current_session()
        unless session.nil?
          shutdown_msg = "Server shut down, goodbye #{service.clients.count} clients!"
          outdata = session.package_data(shutdown_msg)
          service.send_bytes_to_everyone(outdata)
        end
      end
      # shut down the service
      service.shutdown()
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def font
    return @@font
  end

  #---------------------------------------------------------------------------------------------------------
  def send_data_into_state(data)
    return false if @@application_state.nil?
    @@application_state.recieve_network_data(data)
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  def set_app_state(new_state)
    @@application_state.destroy unless @@application_state.nil?
    @@application_state = new_state
  end

  #---------------------------------------------------------------------------------------------------------
  def update()
    if @initialized_later > 0
      @initialized_later -= 1
    elsif @initialized_later == 0
      start_client_service() if @@service_mode == :tcp_client
      @initialized_later = -1
    end
    @@application_state.update unless @@application_state.nil?
    @@controls.update() unless @@controls.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  def draw()
    @@font.draw_text("FPS: #{Gosu.fps}", 16, 4, 0, 1, 1, 0xFF_ffffff)
    @@application_state.draw unless @@application_state.nil?
  end
end
