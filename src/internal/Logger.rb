#===============================================================================================================================
# !!! Logger.rb   |  Instead of having puts() and print() all over, funnel through this module instead.
#-------------------------------------------------------------------------------------------------------------------------------
# https://www.rubydoc.info/stdlib/core/2.0.0/Kernel
#===============================================================================================================================
module Logger
  module Level
    # The levels of logging
    IGNORE = 0
    ERROR  = 1
    WARN   = 2
    DEBUG  = 3
    INFO   = 4
    # The configurations of how the levels log things individually.
    # Sharing strings to objects that also can do things with it. 
    # Can do puts/prints, draw in GUI, maybe to file?
    CONFIG = {
      Level::IGNORE => { to_console: false, to_gui: false, to_file: false },
      Level::ERROR  => { to_console:  true, to_gui:  true, to_file: false },
      Level::WARN   => { to_console:  true, to_gui:  true, to_file: false },
      Level::DEBUG  => { to_console:  true, to_gui: false, to_file: false },
      Level::INFO   => { to_console:  true, to_gui: false, to_file: false }
    }
  end
  # Runtime configuration constants defined below.
  LEVEL = Level::WARN       # What level of logging to provide filtering for.
  USE_CALL_TRACING = false  # When Logger is used, show where it was called from in the console.
  #--------------------------------------
  # If sharing string with a GUI object, ber sure that it bound for method calling required to recieve arguments.
  @@bound_ApplicationWindow = nil
  @@paused = false
  #---------------------------------------------------------------------------------------------------------
  # For most part all logging levels behave the same when called.
  def self.handle(level, lable, msg)
    if Level::CONFIG[level][:to_console]
      puts("#{lable}-> #{msg}")
      self.show_caller_location() if Logger::USE_CALL_TRACING
    end
    self.write_to_gui(lable, msg) if Level::CONFIG[level][:to_gui]
  end
  #---------------------------------------------------------------------------------------------------------
  def self.error(title = "", msg = "")
    return if @@paused
    return unless Logger::LEVEL >= Level::ERROR
    lable = "ERROR: (#{title})"
    self.handle(Level::ERROR, lable, msg)
  end
  #---------------------------------------------------------------------------------------------------------
  def self.warn(title = "", msg = "")
    return if @@paused
    return unless Logger::LEVEL >= Level::WARN
    lable = "WARN: (#{title})"
    self.handle(Level::WARN, lable, msg)
  end
  #---------------------------------------------------------------------------------------------------------
  def self.debug(title = "", msg = "")
    return if @@paused
    return unless Logger::LEVEL >= Level::DEBUG
    lable = "DEBUG: (#{title})"
    self.handle(Level::DEBUG, lable, msg)
  end
  #---------------------------------------------------------------------------------------------------------
  def self.info(title = "", msg = "")
    return if @@paused
    return unless Logger::LEVEL >= Level::INFO
    lable = "INFO: (#{title})"
    self.handle(Level::INFO, lable, msg)
  end
  #---------------------------------------------------------------------------------------------------------
  # Show where the Logger call originated from.
  def self.show_caller_location()
    short_stack_trace = caller_locations(3, 1)
    puts("Log called from:\n#{short_stack_trace.join("\n")}")
    return short_stack_trace
  end
  #---------------------------------------------------------------------------------------------------------
  # Make a request to send a passed string to an ApplicationWindow where it might know how to display it there.
  def self.write_to_gui(lable = "", msg = "")
    return if @@paused
    return false if @@bound_ApplicationWindow.nil?
    unless @@bound_ApplicationWindow.send(:logger_write, "#{lable}-> #{msg}")
      self.error("Logger", "There is a bound Window but no method to write into.")
      return false
    end
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  # If utilizing an ApplicationWindow in a GUI mode, these messages can also be logged to a GUI Component
  # given there is an active state that will proccess recieving these logging messages.
  def self.bind_application_window(parent_window)
    case parent_window
    when ApplicationWindow
      @@bound_ApplicationWindow = parent_window
      return true
    when Gosu::Window
      @@bound_ApplicationWindow = parent_window
      return true
    end
    # The request to bind passed 'parent_window' was of an object type unkown
    return false
  end
  #---------------------------------------------------------------------------------------------------------
  def self.paused?
    return @@paused
  end
  #---------------------------------------------------------------------------------------------------------
  def self.pause()
    @@paused = true
  end
  #---------------------------------------------------------------------------------------------------------
  def self.unpause()
    @@paused = false
  end
end
