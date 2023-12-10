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
    @align = options[:align] || :left # How to position based off x and y location.
    # using the text with out passing :width can automatically set @width
    @text = options[:text] || ''
    font_size = options[:font_size] || 24
    @font = Gosu::Font.new(parent_window, "verdana", font_size)
    @width  = options[:width]  || @font.text_width(@text, 1.0).round()
    @height = options[:height] || font_size * 2
    @box_edge_buf = font_size #DV Add a little to the box so not touching text on edges.
    @width += (@box_edge_buf * 2)
    # set working colors
    color = options[:color] || [Gosu::Color.argb(0xff_6633ff), Gosu::Color.argb(0xff_cc3355)]
    @color  = color[0] #DV Red, Green, Blue, Alpha (00, 00, 00, 00) (ff, ff, ff, ff)
    @hcolor = color[1] #DV Mouse over box hover color
    @is_highlighted = false
    @is_depresed = false
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
    return if @disposed || @@parent_window.nil?
    return unless mouse_hover?()
    action() if @@parent_window.controls.trigger?(:mouse_lclick)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Check to see if the mouse is on-top of the button, then if it is, update sprite actions.
  def mouse_hover?()
    mouse_x = @@parent_window.mouse_x.to_i
    mouse_y = @@parent_window.mouse_y.to_i
    case @align
    when :right
      mouse_x += @width
    when :center
      mouse_x += @width / 2
      mouse_y += @height / 2
    end
    @is_highlighted = (mouse_x > @x && mouse_x < @x + @width && mouse_y > @y && mouse_y < @y + @height)
    @is_depresed = false unless @is_highlighted
    return @is_highlighted
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return if @disposed || @@parent_window.nil?
    return if @box_edge_buf.nil?
    color = @is_highlighted ? @hcolor : @color
    screen_x = @x
    screen_y = @y
    case @align
    when :right
      screen_x -= @width
    when :center
      screen_x -= @width / 2
      screen_y -= @height / 2
    end
    draw_background(screen_x, screen_y, color)
    # draw the text/contents of the Button
    screen_x += @box_edge_buf
    screen_y += (@box_edge_buf / 2)
    @font.draw_text(@text, screen_x, screen_y, 0, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  def draw_background(screen_x, screen_y, color)
    #@@parent_window.draw_rect(screen_x, screen_y, @width, @height, color)
    @bgimg = BlobDraw.get_image({
      of: :round_rect, width: @width, height: @height, radius: 16, outlined: true
    }) if @bgimg.nil?
    @bgimg.draw(screen_x, screen_y, 0, 1.0, 1.0, color)
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
  #---------------------------------------------------------------------------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @disposed = true
    @bgimg = nil
  end
  #---------------------------------------------------------------------------------------------------------
  def disposed?
    return @disposed
  end
end
