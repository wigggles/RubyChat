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
    # make the text field
    @console_box = ConsoleBox.new(parent_window)
    options = {
      :width => @console_box.width,
      :x => @console_box.x,
      :y => @console_box.y + @console_box.height + 4,
      :owner => self,
      :action => :text_action
    }
    @command_field = TextField.new(parent_window, options)
    # set the default game world
    set_game_world(World_00.new(self))
  end
  #---------------------------------------------------------------------------------------------------------
  # Draw to screen.
  def draw
    return if @@parent_window.nil?
    username = @@parent_window.current_session.nil? ? "'nil'" : @@parent_window.current_session.username
    @@parent_window.font.draw_text("#{username}", 128, 4, 0, 1, 1, 0xFF_ffffff)
    @console_box.draw unless @console_box.nil?
    @command_field.draw unless @command_field.nil?
  end
  #---------------------------------------------------------------------------------------------------------
  # Set the world where it's objects are located in and about.
  def set_game_world(world_class)
    @@game_world = world_class
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when action is used on TextField.
  def text_action(string = "")
    #puts("DEBUG: MainState TextField return value: #{string}")
    if PACKAGE_MESSAGE_STRING
      data_package = @@parent_window.getNew_session_package()
      if data_package.nil?
        puts("WARN: MainState TextField could not create a new session package for sending data.")
        @console_box.push_text("> You are not currently connected to any server.") unless @console_box.nil?
      else
        data_package.pack_dt_string(string)
        @@parent_window.send_socket_data(data_package)
      end
    else
      @@parent_window.send_socket_data(string)
    end
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # If network service is working with a TCPSessionData::Package handle how the incoming data is used.
  def proccess_incoming_session_dataPackage(package)
    own_package = @@parent_window.current_session.username == package.user_id
    status_string = ""
    # behave based on packaged data type
    case package.data_mode
    when TCPSessionData::Package::DATAMODE::STRING
      if own_package
        status_string = "(me)> #{package.data}"
      else
        status_string = "(#{package.user_id})> #{package.data}"
      end
    when TCPSessionData::Package::DATAMODE::OBJECT
      if @@game_world.is_a?(GameWorld)
        @@game_world.world_object_sync(package.object_data())
      else
        puts("ERROR: MainState recieved an object data package but doesn't have an active GameWorld.")
      end
    else
      puts("ERROR: MainState recieved a data package set in a mode it doesn't know. (#{package.inspect})")
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
    #puts("DEBUG: MainState recieved network data (#{package.inspect})")
    case package
    when TCPSessionData::Package
      return if @@parent_window.current_session.nil?
      display_string = proccess_incoming_session_dataPackage(package)
    when Array
      return if @@parent_window.current_session.nil?
      if package.length == TCPSessionData::Package::ARRAY_LENGTH
        session_start_time, from_user, message = package
        if @@parent_window.current_session.username == from_user
          display_string = "(me)> #{message}"
        else
          display_string = "(#{from_user})> #{message}"
        end
      end
    when String
      display_string = package
    else
      puts("WARN: GUI malformed data passage. #{package.inspect}")
      display_string = "!!network data error!!"
    end
    # show the message in the UI by pushing the text into ConsoleBox component
    return if display_string.length < 1
    @console_box.push_text(display_string) unless @console_box.nil?
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop, where things get up to date!
  def update
    @console_box.update unless @console_box.nil?
    @command_field.update unless @command_field.nil?
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when the menu is shut, it releases things back to GC.
	def dispose
    @console_box.dispose unless @console_box.nil?
    @command_field.dispose unless @command_field.nil?
	end
end
