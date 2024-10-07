#===============================================================================================================================
# !!!   MainState.rb  |  This is the Stage that manages the chat user interfaces.
#===============================================================================================================================
class MainState
  PACKAGE_MESSAGE_STRING = true  # Package outgoing message string in this class, else have SessionData handle it.
  #---------------------------------------------------------------------------------------------------------
  # Create klass object.
  def initialize()
    # create a text viewing window
    @console_box = GUI::ConsoleBox.new(
      width: $application.width / 8 * 3,
      height: $application.height - 64 - 56,
      x: 8, y: 56
    )
    # make a text input field
    @command_field = GUI::TextField.new(
      owner: self,
      width: @console_box.width,
      x: @console_box.x,
      y: @console_box.y + @console_box.height + 4,
      action: :text_action,
      regex_accept: /[^a-zA-Z0-9 ]/
    )
    # make a few buttons
    @buttons = [
      GUI::Button.new(
        text: "Spam 5",
        owner: self, action: :button_action,
        x: $application.width - 4, y: 4, align: :right
      ),
      GUI::CheckBox.new(
        owner: self, action: :checkbox_action, radius: 12,
        x: $application.width - 148, y: 28, align: :center
      )
    ]
    # set the default game world
    options = {
      x: @console_box.right + 4,
      y: @console_box.y,
      view_width: $application.width - @console_box.width - 18,
      view_height: @console_box.height + @command_field.height + 4
    }
    @game_world = nil
    set_game_world(World_00.new(self, options))
  end
  #---------------------------------------------------------------------------------------------------------
  # Set the world where it's objects are located in and about.
  def set_game_world(world_class)
    @game_world = world_class
  end
  #---------------------------------------------------------------------------------------------------------
  # Attempt to get a new package Object from any active sessions so new data can be loaded into it.
  def get_new_network_package()
    data_package = $application.getNew_session_package()
    if data_package.nil?
      # can also just assume that this client session is not connected to a server if nil
      Logger.warn("MainState", "TextField could not create a new session package for sending data.",
        tags: [:State]
      )
      @console_box.push_text("> You are not currently connected to any server.") unless @console_box.nil?
    end
    return data_package
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when action is used on a CheckBox.
  def checkbox_action(state = false)
    Logger.info("MainState", "CheckBox was toggled. (#{state.inspect})",
      tags: [:GUI, :State]
    )
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when action is used on a Button.
  def button_action()
    data_package = get_new_network_package()
    return nil if data_package.nil?
    data_package.pack_dt_string("Spam 5 messages Button used.")
    Logger.info("MainState", "Button sending 5 session data packages.",
      tags: [:GUI, :State]
    )
    5.times { |time|
      $application.send_socket_data(data_package)
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
      Logger.info("MainState", "TextField to send String session data package. (#{data_package.inspect})",
        tags: [:GUI, :State]
      )
      $application.send_socket_data(data_package)
    else
      Logger.info("MainState", "TextField sending String as socket data. (#{string.inspect})",
        tags: [:GUI, :State]
      )
      $application.send_socket_data(string)
    end
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # If network service is working with a TCPsession::Package handle how the incoming data is used.
  def process_incoming_session_dataPackage(package)
    # if the package does not have a user name, assume it originated from self. TODO: A better method here.
    own_package = true
    unless package.ref_id.nil?
      own_package = $application.current_session.is_self?(package.ref_id)
    end
    status_string = ""
    Logger.debug("MainState", "received a new network_package in DATAMODE:(#{package.data_mode}).",
      tags: [:State]
    )
    Logger.info("MainState", "Processing network_package\nPackage:(#{package.inspect}).",
      tags: [:State]
    )
    # behave based on packaged data type
    case package.data_mode
    when TCPsession::Package::DATAMODE::STRING
      if own_package
        status_string = "(me)> #{package.data}"
      else
        client_description = $application.get_clients.find_client(search_term: package.ref_id)
        if client_description
          status_string = "(#{client_description.username})> #{package.data}"
        else
          status_string = "(#{package.ref_id})> #{package.data}"
        end
      end
    when TCPsession::Package::DATAMODE::CLIENT_SYNC
      unless $application.is_server?()
        client_pool = $application.get_clients()
        client_pool.sync_requested(package)
      else
        Logger.debug("MainState", "Server is syncing the client pool.",
          tags: [:State]
        )
      end
    when TCPsession::Package::DATAMODE::OBJECT
      if @game_world.is_a?(GameWorld)
        @game_world.world_object_sync(package.object_data())
      else
        Logger.error("MainState", "received an object data package but doesn't have an active GameWorld.",
          tags: [:State]
        )
      end
    when TCPsession::Package::DATAMODE::MAP_SYNC
      if @game_world.is_a?(GameWorld)
        @game_world.world_sync(package.mapsync_data())
      else
        Logger.error("MainState", "received a map sync data package but doesn't have an active GameWorld.",
          tags: [:State]
        )
      end
    else
      Logger.error("MainState", "received a data package set in a mode it doesn't know. (#{package.inspect})")
      status_string = "!Malformed Data Package!"
    end
    # return status
    return status_string
  end
  #---------------------------------------------------------------------------------------------------------
  # Network session has received data, process it.
  def receive_network_data(package)
    return if $application.nil?
    display_string = ""
    case package
    when TCPsession::Package
      return if $application.current_session.nil?
      case package.data_mode
      when TCPsession::Package::DATAMODE::STRING
        display_string = process_incoming_session_dataPackage(package)
        Logger.debug("MainState", "received string package, displaying message. (#{display_string.inspect})",
          tags: [:State]
        )
      when TCPsession::Package::DATAMODE::CLIENT_SYNC
        Logger.debug("MainState", "received client package, syncing with it.",
          tags: [:State]
        )
        process_incoming_session_dataPackage(package)
      else
        # do nothing with the package that was received
        Logger.info("MainState", "received network packaged data (#{package.inspect})",
          tags: [:State]
        )
      end
    when String
      display_string = package
      Logger.info("MainState", "received network raw string data (#{package.inspect})",
        tags: [:State]
      )
    else
      Logger.warn("MainState", "GUI malformed data passage. #{package.inspect}",
        tags: [:State]
      )
      display_string = "!!network data error!!"
    end
    # show the message in the UI by pushing the text into ConsoleBox component
    return if display_string.length < 1
    @console_box.push_text(display_string) unless @console_box.nil?
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop, where things get up to date!
  def update
    @game_world.update() unless @game_world.nil?
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
    return if $application.nil?
    @game_world.draw() unless @game_world.nil?
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
    unless $application.self_client_description.nil?
      username = $application.self_client_description.username
    else
      username = "'nil'"
    end
    $application.font.draw_text("#{username}", 128, 4, 0, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  # Called when the menu is shut, it releases things back to GC.
	def dispose
    @game_world.dispose() unless @game_world.nil?
    @console_box.dispose unless @console_box.nil?
    @command_field.dispose unless @command_field.nil?
    @buttons.each { |button|
      button.dispose()
    }
	end
end
