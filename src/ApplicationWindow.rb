#=====================================================================================================================
# !!!  ApplicationWindow.rb |  An interactive Gosu Window based chat GUI.
#=====================================================================================================================
require 'socket'
require 'gosu'

require './src/internal/InputControls'

require './src/network/ClientPool'
require './src/network/TCP/session-Package'
require './src/network/TCP/session'
require './src/network/TCP/server'
require './src/network/TCP/client'

require './src/GUI/Component'
require './src/GUI/BlobDraw'
require './src/GUI/Components/Button'
require './src/GUI/Components/CheckBox'
require './src/GUI/Components/TextField'
require './src/GUI/Components/ConsoleBox'
require './src/GUI/Components/TextWall'

require './src/States/MainState'

require './src/Game/GameWorld'
require './src/Game/WorldObject'
require './src/Game/World_00'

#=====================================================================================================================
class ApplicationWindow < Gosu::Window
  attr_reader :font, :service_mode

  #---------------------------------------------------------------------------------------------------------
  # Construct a server and listen for/to clients, or be a client and connect to a server.
  def initialize(
    is_server = false,
    fullscreen: Configuration::FULL_SCREEN, resizable: Configuration::RESIZABLE,
    borderless: false, update_interval: Configuration::GOSU_UPDATE_MS
  )
    @service_mode = nil || :offline
    GC.start
    @disposed = false
    # create a new Gosu::Window
    super(
      Configuration::INITIAL_SCREEN_WIDTH, Configuration::INITIAL_SCREEN_HEIGHT, {
        fullscreen: fullscreen, resizable: resizable && !fullscreen,
        borderless: borderless, update_interval: update_interval
      }
    )
    @font = Gosu::Font.new(self, nil, 24)
    @controls = InputControls.new
    # create a new session socket manager
    @is_server = is_server
    # start up the GUI's initial state manager
    $application = self
    self.caption = 'Gosu Network Demo'
    @application_state = nil
    start_app_state(MainState.new)
    # delay the autostart of network services, this provides enough time for the GUI to be created
    Thread.new do
      sleep(0.1)
      if is_server
        @service_mode = :tcp_server
        start_server_service
      else
        @username = ARGV[0] || 'GosuGUI_01'
        @service_mode = :tcp_client
        start_client_service if @service_mode == :tcp_client
      end
      # allow Logger to write into the '@application_state' if that Object has a method for it
      Logger.bind_application_window(self)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def self.screen_width
    return 0 if $application.nil?

    @width
  end

  def self.screen_height
    return 0 if $application.nil?

    @height
  end

  #---------------------------------------------------------------------------------------------------------
  def needs_cursor?
    true
  end

  #---------------------------------------------------------------------------------------------------------
  # Required to display upon request the Gosu licensing.
  def show_gosu_legal
    start_app_state(LicensesState.new)
  end

  #---------------------------------------------------------------------------------------------------------
  # Check if application is acting as the server, also checks if its running a network session.
  def is_server?
    if @is_server
      return false if current_session.nil?

      return true
    end
    false
  end

  #---------------------------------------------------------------------------------------------------------
  # Check if the application acting as a client, also checks if there is an active network session.
  def is_client?
    unless @is_server
      return false if current_session.nil?

      return true
    end
    false
  end

  #---------------------------------------------------------------------------------------------------------
  # If not already a client or running a server, start a new network server instance.
  def start_server_service
    case @service_mode
    when :tcp_server
      @server = TCPserver.new
      send_data_into_state('TCPServer started, listening...')
      Thread.new do
        @server.listen(self)
      end
    else
      Logger.error('ApplicationWindow', "Unknown socket server type. (#{@service_mode})")
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # If not a server or already a client, start a new network client instance.
  def start_client_service
    send_data_into_state('Attempting to connect to server...')
    case @service_mode
    when :tcp_client
      Thread.new do
        @client = TCPclient.new('localhost')
        if @client.error.nil?
          @client.start_session(@username)
          start_client_session
          @client.connect(report_to: self)
        else
          Logger.error('ApplicationWindow', 'Failed to start client session.')
        end
      end
    else
      Logger.error('ApplicationWindow', "Unknown socket client type. (#{@service_mode})")
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def start_client_session
    if @client.nil?
      send_data_into_state('Can not start session.')
    elsif @client.session.nil?
      send_data_into_state('Server not found.')
    else
      send_data_into_state('Client touched server.')
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # :D Called by Gosu::Window when a button was pressed, but was now released.
  def button_up(id)
    return if @controls.nil?

    @controls.button_up(id)
    super(id)
  end

  #---------------------------------------------------------------------------------------------------------
  # :D Called by Gosu::Window when a button has been pressed.
  def button_down(id)
    return if @controls.nil?

    @controls.button_down(id)
    super(id)
  end

  def gamepad_connected(index); end

  def gamepad_disconnected(index); end

  def controls
    @controls
  end

  #---------------------------------------------------------------------------------------------------------
  # Get the current network session socket between two separate synced network services based on current mode.
  def current_session
    case @service_mode
    when :tcp_server
      return nil if @server.nil?

      @server.session
    when :tcp_client
      return nil if @client.nil?

      @client.session
    end
    # else is :offline, return nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Application window focus status from Operating System.
  def gain_focus; end

  def lose_focus; end

  #---------------------------------------------------------------------------------------------------------
  # Get 'self' local session's Client description.
  def self_client_description
    session = current_session
    return session.description unless session.nil?

    nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Get the client pool as reported by the server.
  def get_clients
    session = current_session
    return session.get_client_pool unless session.nil?

    nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Get the network service the current application mode is set to operate in.
  def network_service
    case @service_mode
    when :tcp_server
      @server
    when :tcp_client
      @client
    else # :offline
      nil
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Used to utilize the open session socket to send data.
  def send_socket_data(data)
    return nil if network_service.nil?
    return nil if current_session.nil?

    case @service_mode
    when :tcp_server
      case data
      when TCPsession::Package
        data.set_server_time
        data_byte_string = data.get_packed_string
      when String
        data_byte_string = current_session.package_data(data)
      else
        Logger.error('ApplicationWindow', "Server attempting to send Unknown data type. (#{data.class})")
        return nil
      end
      Logger.debug('ApplicationWindow', "Server sending data. (#{data.inspect})")
      @server.send_bytes_to_everyone(data_byte_string, [])
    when :tcp_client
      Logger.debug('ApplicationWindow', "Client sending data. (#{data.inspect})")
      @client.send_data(data)
    else # :offline
      nil
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Create a new data package for sending information.
  def new_session_package
    return nil if network_service.nil?
    return nil if current_session.nil?

    current_session.empty_data_package
  end

  #---------------------------------------------------------------------------------------------------------
  # Check what running network mode status is for the application.
  def retrive_service_mode
    @service_mode
  end

  #---------------------------------------------------------------------------------------------------------
  # Called when the application was shutdown by normal operation means.
  def close
    Logger.warn('ApplicationWindow', 'Closing application window.')
    shutdown_network
    dispose
    super()
  end

  #---------------------------------------------------------------------------------------------------------
  # If has the chance, will graciously shut down by informing all the listening clients.
  def shutdown_network
    service = network_service
    return if service.nil?

    # inform the clients the server is shutting down
    if @is_server
      session = current_session
      unless session.nil?
        shutdown_msg = "Server shut down, goodbye #{service.client_pool.count} clients!"
        out_data = session.package_data(shutdown_msg)
        service.send_bytes_to_everyone(out_data)
      end
    end
    # shut down the service
    service.shutdown
  end

  #---------------------------------------------------------------------------------------------------------
  # If taking advantage of the Logger module, log strings can be shared into the GUI experience.
  def logger_write(string_msg = '')
    send_data_into_state(string_msg)
    true
  end

  #---------------------------------------------------------------------------------------------------------
  def send_data_into_state(data)
    return false if @application_state.nil?

    @application_state.receive_network_data(data)
    true
  end

  #---------------------------------------------------------------------------------------------------------
  def start_app_state(new_state)
    @application_state.destroy unless @application_state.nil?
    @application_state = new_state
  end

  #---------------------------------------------------------------------------------------------------------
  # Gosu bindings for the operating system's running environment provide a 'tick()' which is used as a game
  # clock. This clock loop is what checks for updates in a timely fashion. This clock should not be blocked.
  def update
    return if disposed?

    # update the manager state and shared input controls
    @application_state.update unless @application_state.nil?
    @controls.update unless @controls.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # To keep things robust and fluid, GUI states are handled independently of the ApplicationWindow. This
  # provides the states for GarbageCollection in a simpler fashion. This also provides a way of changing states
  # with ease, so if a state is a WorldMap or a Menu this transition/interaction can be handled by the Application.
  def draw
    @font.draw_text("FPS: #{Gosu.fps}", 16, 4, 0, 1, 1, 0xFF_ffffff)
    @application_state.draw unless @application_state.nil?
  end

  #---------------------------------------------------------------------------------------------------------
  # Flag this class as being disposed of, which means it announces do not use me, im getting rid of my things.
  # This most notably happens on and around shutdowns.
  def dispose
    @disposed = true
  end

  #---------------------------------------------------------------------------------------------------------
  # Return a boolean based on if this (self) Object has been flagged for cleanup.
  def disposed?
    @disposed
  end
end
