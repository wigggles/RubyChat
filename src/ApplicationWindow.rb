#===============================================================================================================================
# !!!  ApplicationWindow.rb |  An interactive Gosu Window based chat GUI.
#===============================================================================================================================
require 'socket'
require 'gosu'

require './src/internal/Logger.rb'
require './src/internal/InputControls.rb'

require './src/network/TCPSessionData.rb'
require './src/network/TCPserver.rb'
require './src/network/TCPclient.rb'

require './src/GUI/Components/TextField.rb'
require './src/GUI/Components/ConsoleBox.rb'
require './src/GUI/MainState.rb'

require './src/Game/GameWorld.rb'
require './src/Game/WorldObject.rb'
require './src/Game/World_00.rb'

#===============================================================================================================================
class ApplicationWindow < Gosu::Window
  @@application_state = nil
  @@controls = nil
  @@font = nil
  @@service_mode = nil || :offline

  #---------------------------------------------------------------------------------------------------------
  # Construct a server and listen for/to clients, or be a client and connect to a server.
  def initialize(is_server = false)
    GC.start()
    @disposed = false
    # create a new Gosu::Window
    super(Configuration::SCREEN_WIDTH, Configuration::SCREEN_HEIGHT, Configuration::FULLSCREEN)
    @@font = Gosu::Font.new(self, nil, 24)
    @@controls = InputControls.new(self)
    # create a new session socket manager
    @is_server = is_server
    # start up the GUI's initial state manager
    set_app_state(MainState.new(self))
    # delay the autostart of network services, this provides enough time for the GUI to be created
    Thread.new {
      sleep(0.5)
      if is_server
        @@service_mode = :tcp_server
        start_server_service()
      else
        @username = ARGV[0] || "GosuGUI_01"
        @@service_mode = :tcp_client
        start_client_service() if @@service_mode == :tcp_client
      end
      # allow Logger to write into the '@application_state' if that Object has a method for it
      Logger.bind_application_window(self) 
    }
  end

  #---------------------------------------------------------------------------------------------------------
  # Check if application is acting as the server, also checks if its running a network session.
  def is_server?
    if @is_server
      return false if current_session().nil?
      return true
    end
    return false
  end

  #---------------------------------------------------------------------------------------------------------
  # Check if the application acting as a client, also checks if there is an active network session.
  def is_client?
    unless @is_server
      return false if current_session().nil?
      return true
    end
    return false
  end

  #---------------------------------------------------------------------------------------------------------
  # If not already a client or running a server, start a new network server instance.
  def start_server_service()
    case @@service_mode
    when :tcp_server
      @server = TCPserver.new()
      send_data_into_state("TCPServer started, listening...")
      Thread.new {
        @server.listen(self)
      }
    else
      Logger.error("ApplicationWindow", "Unkown socket server type. (#{@@service_mode})")
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # If not a server or already a client, start a new network client instance.
  def start_client_service()
    send_data_into_state("Attempting to connect to server...")
    case @@service_mode
    when :tcp_client
      Thread.new { 
        @client = TCPclient.new("localhost")
        if @client.error.nil?
          @client.start_session(@username)
          start_client_session()
          @client.connect(self)
        else
          Logger.error("ApplicationWindow", "Failed to start client session.")
        end
      }
    else
      Logger.error("ApplicationWindow", "Unkown socket client type. (#{@@service_mode})")
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
        data.set_server_time()
        data_byte_string = data.get_packed_string()
      when String
        data_byte_string = current_session.package_data(data)
      else
        Logger.error("ApplicationWindow", "Server attempting to send unkown data type. (#{data.class})")
        return nil
      end
      Logger.debug("ApplicationWindow", "Server sending data. (#{data.inspect})")
      return @server.send_bytes_to_everyone(data_byte_string, [])
    when :tcp_client
      Logger.debug("ApplicationWindow", "Client sending data. (#{data.inspect})")
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
    Logger.warn("ApplicationWindow", "Closing application window.")
    shutdown_network()
    dispose()
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
  # If taking advantage of the Logger module, log strings can be shared into the GUI experience.
  def logger_write(string_msg = "")
    send_data_into_state(string_msg)
    return true
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
  # Gosu bindings for the operating system's running environment provide a 'tick()' which is used as a game
  # clock. This clock loop is what checks for updates in a timley fasion. This clock should not be blocked.
  def update()
    return if disposed?
    # update the manager state and shared input controls
    @@application_state.update unless @@application_state.nil?
    @@controls.update() unless @@controls.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # To keep things robust and fluid, GUI states are handled independently of the ApplicationWindow. This
  # provides the states for GarbageCollection in a simpler fasion. This also provides a way of changing states
  # with ease, so if a state is a WorldMap or a Menu this transition/interaction can be handled by the Application.
  def draw()
    @@font.draw_text("FPS: #{Gosu.fps}", 16, 4, 0, 1, 1, 0xFF_ffffff)
    @@application_state.draw unless @@application_state.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # Flag this class as being disposed of, which means it anounces do not use me, im getting rid of my things.
  # This most notibly happens on and around shutdowns.
  def dispose()
    @disposed = true
  end

  #---------------------------------------------------------------------------------------------------------
  # Return a boolean based on if this (self) Object has been flagged for cleanup.
  def disposed?
    return @disposed
  end
end
