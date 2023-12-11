#===============================================================================================================================
# !!!   MainState.rb  |  This is the Stage that manages the chat user interfaces.
#===============================================================================================================================
class MainState
  PACKAGE_MESSAGE_STRING = true  # Package outgoing message string in this class, else have SessionData handle it.

  @@parent_window = nil
  @@game_world = nil

  #---------------------------------------------------------------------------------------------------------
  # Create klass object.
  def initialize(parent_window)
    @@parent_window = parent_window
    # create a text viewing window
    options = {
      :width => Configuration::SCREEN_WIDTH / 8 * 3,
      :x => 8, :y => 56
    }
    options[:height] = Configuration::SCREEN_HEIGHT - options[:y] - 64
    @console_box = GUI::ConsoleBox.new(options)
    # make a text input field
    options = {
      :width => @console_box.width,
      :x => @console_box.x,
      :y => @console_box.y + @console_box.height + 4,
      :owner => self,
      :action => :text_action
    }
    @command_field = GUI::TextField.new(options)
    # make a few buttons
    @buttons = [
      GUI::Button.new({
        text: "Spam 5",
        owner: self, action: :button_action,
        x: @@parent_window.width - 4, y: 4, align: :right
      }),
      GUI::CheckBox.new({
        owner: self, action: :checkbox_action, radius: 12,
        x: @@parent_window.width - 148, y: 28, align: :center
      })
    ]
    # set the default game world
    options = {
      x: @console_box.right + 4,
      y: @console_box.y,
      view_width: Configuration::SCREEN_WIDTH - @console_box.width - 18,
      view_height: @console_box.height + @command_field.height + 4
    }
    set_game_world(World_00.new(self, options))
  end
  #---------------------------------------------------------------------------------------------------------
  # Set the world where it's objects are located in and about.
  def set_game_world(world_class)
    @@game_world = world_class
  end
  #---------------------------------------------------------------------------------------------------------
  # Attempt to get a new package Object from any active sessions so new data can be loaded into it.
  def get_new_network_package()
    data_package = @@parent_window.getNew_session_package()
    if data_package.nil?
      Logger.warn("MainState", "TextField could not create a new session package for sending data.")
      @console_box.push_text("> You are not currently connected to any server.") unless @console_box.nil?
    end
    return data_package
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when action is used on a CheckBox.
  def checkbox_action(state = false)
    Logger.info("MainState", "CheckBox was toggled. (#{state.inspect})")
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when action is used on a Button.
  def button_action()
    data_package = get_new_network_package()
    return nil if data_package.nil?
    data_package.pack_dt_string("Spam 5 messages Button used.")
    Logger.info("MainState", "Button sending 5 session data packages.")
    5.times { |time|
      @@parent_window.send_socket_data(data_package)
    }
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when action is used on TextField.
  def text_action(string = "")
    Logger.debug("MainState", "TextField return value: #{string}")
    if MainState::PACKAGE_MESSAGE_STRING
      data_package = get_new_network_package()
      return nil if data_package.nil?
      data_package.pack_dt_string(string)
      Logger.info("MainState", "TextField to send String session data package. (#{data_package.inspect})")
      @@parent_window.send_socket_data(data_package)
    else
      Logger.info("MainState", "TextField sending String as socket data. (#{string.inspect})")
      @@parent_window.send_socket_data(string)
    end
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # If network service is working with a TCPsession::Package handle how the incoming data is used.
  def proccess_incoming_session_dataPackage(package)
    own_package = @@parent_window.current_session.is_self?(package.user_id)
    status_string = ""
    Logger.debug("MainState", "Recieved a new network_package in DATAMODE:(#{package.data_mode}).")
    Logger.info("MainState", "Processing network_package\nPackage:(#{package.inspect}).")
    # behave based on packaged data type
    case package.data_mode
    when TCPsession::Package::DATAMODE::STRING
      if own_package
        status_string = "(me)> #{package.data}"
      else
        status_string = "(#{package.user_id})> #{package.data}"
      end
    when TCPsession::Package::DATAMODE::CLIENT_SYNC
      client_pool = @@parent_window.get_clients()
      client_pool.sync_requested(package)
    when TCPsession::Package::DATAMODE::OBJECT
      if @@game_world.is_a?(GameWorld)
        @@game_world.world_object_sync(package.object_data())
      else
        Logger.error("MainState", "Recieved an object data package but doesn't have an active GameWorld.")
      end
    when TCPsession::Package::DATAMODE::MAP_SYNC
      if @@game_world.is_a?(GameWorld)
        @@game_world.world_sync(package.mapsync_data())
      else
        Logger.error("MainState", "Recieved a map sync data package but doesn't have an active GameWorld.")
      end
    else
      Logger.error("MainState", "Recieved a data package set in a mode it doesn't know. (#{package.inspect})")
      status_string = "!Malformed Data Package!"
    end
    # return status
    return status_string
  end
  #---------------------------------------------------------------------------------------------------------
  # Network session has recieved data, proccess it.
  def recieve_network_data(package)
    return if @@parent_window.nil?
    display_string = ""
    case package
    when TCPsession::Package
      return if @@parent_window.current_session.nil?
      case package.data_mode
      when TCPsession::Package::DATAMODE::STRING
        display_string = proccess_incoming_session_dataPackage(package)
        Logger.debug("MainState", "Recieved string package, displaying it. (#{display_string.inspect})")
      else
        Logger.info("MainState", "Recieved network packaged data (#{package.inspect})")
      end
    when String
      display_string = package
      Logger.info("MainState", "Recieved network raw string data (#{package.inspect})")
    else
      Logger.warn("MainState", "GUI malformed data passage. #{package.inspect}")
      display_string = "!!network data error!!"
    end
    # show the message in the UI by pushing the text into ConsoleBox component
    return if display_string.length < 1
    @console_box.push_text(display_string) unless @console_box.nil?
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop, where things get up to date!
  def update
    @@game_world.update() unless @@game_world.nil?
    # after updating the world, then update the UI
    @console_box.update unless @console_box.nil?
    @command_field.update unless @command_field.nil?
    @buttons.each { |button|
      button.update()
    }
  end
  #---------------------------------------------------------------------------------------------------------
  # Draw to screen.
  def draw
    return if @@parent_window.nil?
    @@game_world.draw() unless @@game_world.nil?
    # after drawing the world and its WorldObjects, draw the UI over top of it
    draw_local_description()
    @console_box.draw unless @console_box.nil?
    @command_field.draw unless @command_field.nil?
    @buttons.each { |button|
      button.draw()
    }
  end
  #---------------------------------------------------------------------------------------------------------
  def draw_local_description()
    unless @@parent_window.self_client_description.nil?
      username = @@parent_window.self_client_description.username
    else
      username = "'nil'"
    end
    @@parent_window.font.draw_text("#{username}", 128, 4, 0, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when the menu is shut, it releases things back to GC.
	def dispose
    @@game_world.dispose() unless @@game_world.nil?
    @console_box.dispose unless @console_box.nil?
    @command_field.dispose unless @command_field.nil?
    @buttons.each { |button|
      button.dispose()
    }
	end
end
