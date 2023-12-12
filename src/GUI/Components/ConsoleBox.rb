#===============================================================================================================================
# !!!   ConsoleBox.rb | A box that displays Kernel log information to the program's screen.
#===============================================================================================================================
class GUI::ConsoleBox < GUI::Component
  #---------------------------------------------------------------------------------------------------------
  #D: Create object Klass.
  def initialize(options = {})
    @width  = options[:width]  || 0  #DV Width of the viewing Rect.
    @height = options[:height] || 0  #DV Height of the viewing Rect.
    @x = options[:x] || 0
    @y = options[:y] || 0
    @bgcolor = 0xFF_6c6c6c   #DV Background color used to fill viewing Rect.
    font_size = options[:font_size] || 18
    @font = Gosu::Font.new(GUI.parent_window, "verdana", font_size)
    max_char_width = @font.text_width("W").round() * 0.55
    @line_width = (@width / max_char_width).round() #DV Max characters in a line before wrapping.
    @viewable_text = []
    @prevous_text = ""
    @max_lines = @height / font_size # max number of lines to draw, prevents lines being draw off screen.
    super(options)
  end
  #---------------------------------------------------------------------------------------------------------
  def draw_background(screen_x, screen_y, color)
    @bgimg = GUI::BlobDraw.get_image({
      of: :round_rect, width: @width, height: @height, radius: 8, outlined: true
    }) if @bgimg.nil?
    @bgimg.draw(screen_x, screen_y, 0, 1.0, 1.0, color)
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
    if @viewable_text.size >= @max_lines
      @viewable_text.delete_at(@max_lines)
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
    # draw each string line text
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
  #D: Update loop.
  def update()
    return unless super()

  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw screen interactions.
  def draw()
    return unless super()
    draw_background(@x, @y, @bgcolor)
    # draw the text contents
    x = @x + 8
    y = @y + @height - 32
    @viewable_text.each do |line|
      @font.draw_text(line, x, y, 0, 1, 1, 0xFF_ffffff)
      y -= @font.height
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @viewable_text = nil
    @bgimg = nil
    super()
  end
end
