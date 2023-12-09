#===============================================================================================================================
# !!!  Button.rb |  A on screen interactive input object for Gosu window based applications.
#===============================================================================================================================
class Button
  @@parent_window = nil
  
  attr_accessor :x, :y, :color, :hcolor, :text
  #---------------------------------------------------------------------------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(parent_window, options = {})
    @@parent_window = parent_window
    @x = options[:x] || 0
    @y = options[:y] || 0
    @text = options[:text] || ''
    font_size = options[:font_size] || 24
    @font = Gosu::Font.new($window, "verdana", font_size)
    @is_highlighted = false
    @is_depresed = false
    @width  = options[:width]  || @font.text_width(@text, 1.0)
    @height = options[:height] || font_size * 2
    @box_edge_buf = font_size #DV Add a little to the box so not touching text on edges.
    color = options[:color] || [0xffff00ff, 0xffcc00ff]
    @color  = color[0] #DV Red, Green, Blue, Alpha (00, 00, 00, 00) (ff, ff, ff, ff)
    @hcolor = color[1] #DV Mouse over box hover color
    # setup call method for action
    @owner = options[:owner] || nil
    if @owner.nil?
      print("Error with Button no ower, skipping")
      return nil
    end
    @action = options[:action] || nil
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop for button behaviors.
  def update()
    return nil
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @disposed = true
    @action = nil
    @owner = nil
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Check to see if the mouse is on-top of the button, then if it is, update sprite actions.
  def mouse_hover?(mouse_x, mouse_y)
    return if @box_edge_buf.nil?
    mouse_x.to_i
    mouse_y.to_i
    width = @width + (@box_edge_buf * 2)
    x = @x + @box_edge_buf
    over_self = (mouse_x > x && mouse_x < x + width && mouse_y > @y && mouse_y < @y + @height)
    @is_highlighted = over_self
    @is_depresed = false unless @is_highlighted
    return @is_highlighted
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return if @@parent_window.nil?
    return if @box_edge_buf.nil?
    color = @is_highlighted ? @hcolor : @color
    width = @width + (@box_edge_buf * 2)
    x = @x + @box_edge_buf
    @@parent_window.draw_rect(x, @y, width, @height, color)
    x = @x + (@box_edge_buf * 2)
    y = @y + (@box_edge_buf / 2)
    @font.draw_text(@text, x, y, 0, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  #D Try first to catch errors, and call function from parent class user.
  def action()
    return false unless @is_highlighted
    return true if @is_depresed
    @is_depresed = true
    if @action.nil?
      print("There is an error with button\n #{text}\n In: #{@owner}")
      return false
    end
    # use owner class for method call
    test = @owner.send(@action) || nil
    if test.nil?
      return false if @disposed
      Logger.error("Button", "Callback method '#{@action}' in #{@owner} needs to return true.")
      return false
    end
    return true
  end
end
