#===============================================================================================================================
# !!!   ConsoleBox.rb | A box that displays Kernel log information to the program's screen.
#===============================================================================================================================
class ConsoleBox
  MAX_LINES = 30 # max number of lines to draw onto the screen, prevents lines being draw off screen.
  @@parent_window = nil

  attr_accessor :x, :y, :width, :height
  #---------------------------------------------------------------------------------------------------------
  #D: Create object Klass.
  def initialize(parent_window, options = {})
    @@parent_window = parent_window
    @width  = Configuration::SCREEN_WIDTH / 4 * 3  #DV Width of the viewing Rect.
    @height = Configuration::SCREEN_HEIGHT / 4 * 3 #DV Height of the viewing Rect.
    @x = (Configuration::SCREEN_WIDTH - @width) / 2
    @y = (Configuration::SCREEN_HEIGHT - @height) / 2
    @bgcolor = 0xFF_6c6c6c   #DV Background color used to fill viewing Rect.
    font_size = options[:font_size] || 18
    @line_width = (font_size * 6).floor #DV Length of the line to write text to.
    @font = Gosu::Font.new(parent_window, "verdana", font_size)
    @viewable_text = []
    @prevous_text = ""
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop.
  def update()
    
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Push text for display in console window; I.E. System.write_console(string)
  def push_text(console_text = "")
    return if console_text == ""
    # prep string
    prep_console_text(console_text)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Writes to console.
  def display_string(text = "")
    @viewable_text.unshift(text)
    if @viewable_text.size >= MAX_LINES
      @viewable_text.delete_at(MAX_LINES)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Clean text to be shown of any special characters.
  def prep_console_text(string)
    # can't contain special characters.
    string.sub!("\r", "\n")
    if string.include?("\n") 
      lines = string.split("\n")
    end
    if lines.nil?
      lines = [string]
    end
    lines.each do |line|
      if line.length < @line_width
        display_string(line)
      else # break the string up so that all the text fits in the console box.
        line_break = line.scan(/.{1,#{@line_width}}/)
        line_break.each do |line|
          display_string(line)
        end
      end
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw screen interactions.
  def draw()
    return if @@parent_window.nil? # closing program?
    # draw background color of window
    @@parent_window.draw_rect(@x, @y, @width, @height, @bgcolor)
    x = @x + 8
    y = @y + @height - 32
    @viewable_text.each do |line|
      @font.draw_text(line, x, y, 0, 1, 1, 0xFF_ffffff)
      y -= @font.height
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Clean up variables when program closes.
  def dispose()
    
  end
end
