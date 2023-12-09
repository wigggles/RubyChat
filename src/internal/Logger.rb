#===============================================================================================================================
# !!! Logger.rb   |  Instead of having puts() and print() all over, funnel through this module instead.
#-------------------------------------------------------------------------------------------------------------------------------
# https://www.rubydoc.info/stdlib/core/2.0.0/Kernel
#
# https://ruby-doc.org/core-2.5.0/Thread/Backtrace/Location.html
#===============================================================================================================================
module Logger
  USE_CONSOLE_COLORS = true
  # Terminal color codes
  module TermColor
    NONE         = "\e[0m"
    BLACK        = "\e[0;30m"
    GRAY         = "\e[1;30m"
    RED          = "\e[0;31m"
    LIGHT_RED    = "\e[1;31m"
    GREEN        = "\e[0;32m"
    LIGHT_GREEN  = "\e[1;32m"
    BROWN        = "\e[0;33m"
    YELLOW       = "\e[1;33m"
    BLUE         = "\e[0;34m"
    LIGHT_BLUE   = "\e[1;34m"
    PURPLE       = "\e[0;35m"
    LIGHT_PURPLE = "\e[1;35m"
    CYAN         = "\e[0;36m"
    LIGHT_CYAN   = "\e[1;36m"
    LIGHT_GRAY   = "\e[0;37m"
    WHITE        = "\e[1;37m"
  end
  #--------------------------------------
  module TermOps
    CLEAR        = "\033[2J"
  end
  #--------------------------------------
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
      Level::IGNORE => { 
        to_console: false, to_gui: false, to_file: false, show_location: false, use_color: nil
      },
      Level::ERROR  => {
        to_console:  true, to_gui:  true, to_file: false, show_location: true, use_color: TermColor::RED
      },
      Level::WARN   => {
        to_console:  true, to_gui:  true, to_file: false, show_location: true, use_color: TermColor::YELLOW
      },
      Level::DEBUG  => {
        to_console:  true, to_gui: false, to_file: false, show_location: true, use_color: TermColor::GREEN
      },
      Level::INFO   => {
        to_console:  true, to_gui: false, to_file: false, show_location: false, use_color: TermColor::BLUE
      }
    }
  end
  # Runtime configuration constants defined below.
  LEVEL = Level::INFO       # What level of logging to provide filtering for.
  USE_CALL_TRACING = true   # When Logger is used, show where it was called from in the console.
  INCLUDE_TIMESTAMP = true  # Timestamp log entry.
  #--------------------------------------
  # If sharing string with a GUI object, ber sure that it bound for method calling required to recieve arguments.
  @@bound_ApplicationWindow = nil
  @@paused = false
  #---------------------------------------------------------------------------------------------------------
  # For most part all logging levels behave the same when called.
  def self.handle(level, lable, msg)
    if Level::CONFIG[level][:to_console]
      # add timestamp into the logger
      if INCLUDE_TIMESTAMP
        current_time = Time.now()
        stamp = "#{current_time.strftime("%H:%M:%S")}.#{current_time.usec()}"
        if Logger::USE_CONSOLE_COLORS
          print("#{TermColor::PURPLE}[#{TermColor::WHITE}#{stamp}#{TermColor::PURPLE}] #{TermColor::NONE}")
        else
          print("[#{stamp}] ")
        end
      end
      # how to display the text in the conosole
      if Logger::USE_CONSOLE_COLORS
        flag_color = Level::CONFIG[level][:use_color]
        if flag_color
          puts("#{flag_color}#{lable}-> #{TermColor::NONE}#{msg}")
        else
          puts("#{TermColor::NONE}#{lable}-> #{msg}")
        end
      else
        puts("#{lable}-> #{msg}")
      end
      # if tracing where Logger was called from, include that information
      if Logger::USE_CALL_TRACING && Level::CONFIG[level][:show_location]
        self.show_caller_location()
      end
    end
    # if there is a GUI write into that as well
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
    location_of_log_call = "./src/" + short_stack_trace[0].to_s.split('/src/').last()
    puts("^ logged from: #{location_of_log_call}")
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
