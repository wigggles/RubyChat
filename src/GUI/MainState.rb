#===============================================================================================================================
# !!!   MainState.rb  |  This is the Stage that manages the chat user interfaces.
#===============================================================================================================================
class MainState
  @@parent_window = nil

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
  # Called when action is used on TextField.
  def text_action(string = "")
    #puts("MainState TextField return value: #{string}")
    @@parent_window.send_socket_data(string)
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # Network session has recieved data, proccess it.
  def recieve_network_data(data = [])
    return if @@parent_window.nil?
    return if @@parent_window.current_session.nil?
    display_string = ""
    error = true
    case data
    when Array
      if data.length == 3
        session_start_time, from_user, message = data
        if @@parent_window.current_session.username == from_user
          display_string = "(me)> #{message}"
        else
          display_string = "(#{from_user})> #{message}"
        end
        error = false
      end
    when String
      display_string = data
      error = false
    end
    return puts("GUI malformed data passage. #{data.inspect}") if error
    # show the message in the UI by pushing the text into ConsoleBox component
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
