#===============================================================================================================================
# !!!  Button.rb |  Clickable input GUI object for Gosu window based applications.
#===============================================================================================================================
class GUI::Button < GUI::Component
  ACTION_TIMEOUT = 10
  
  attr_accessor :hcolor, :text
  #---------------------------------------------------------------------------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(options = {})
    super(options)
    @align = options[:align] || :left # How to position based off x and y location.
    # using the text with out passing :width can automatically set @width
    @text = options[:text] || ''
    font_size = options[:font_size] || 24
    @font = Gosu::Font.new($application, "verdana", font_size)
    @box_edge_buf = font_size #DV Add a little to the box so not touching text on edges.
    if @width <= 0
      @width  = options[:width]  || @font.text_width(@text).round()
      @width += (@box_edge_buf * 2)
    end
    if @height <= 0
      @height = options[:height] || font_size * 2
    end
    # set working colors
    color = options[:color] || [Gosu::Color.argb(0xff_6633ff), Gosu::Color.argb(0xff_cc3355)]
    @color  = color[0] #DV Red, Green, Blue, Alpha (00, 00, 00, 00) (ff, ff, ff, ff)
    @hcolor = color[1] #DV Mouse over box hover color
    @is_highlighted = false
    @is_depresed = false
    @has_actioned = false
    # setup call method for action
    if @owner.nil?
      print("Error with Button no owner, skipping")
      return nil
    end
    @action = options[:action] || nil
    @action_timeout = GUI::Button::ACTION_TIMEOUT
    is_ready()
  end
  #---------------------------------------------------------------------------------------------------------
  #D Try first to catch errors, and call function from parent class user.
  def action()
    return false unless @is_highlighted
    return true if  @has_actioned
    if @action.nil?
      print("There is an error with button\n #{text}\n In: #{@owner}")
      return false
    end
    # use owner class for method call
    test = @owner.send(@action) || nil
    if test.nil?
      return false if @disposed
      Logger.warn("Button", "Callback method '#{@action}' in #{@owner} needs to return true unless error.",
        tags: [:GUI]
      )
      return false
    end
    @has_actioned = true
    @action_timeout = GUI::Button::ACTION_TIMEOUT
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Check to see if the mouse is on-top of the button, then if it is, update sprite actions.
  def mouse_hover?()
    mouse_x = $application.mouse_x.to_i
    mouse_y = $application.mouse_y.to_i
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
  def draw_background(screen_x, screen_y, color)
    @bgimg = GUI::BlobDraw.get_image({
      of: :round_rect, width: @width, height: @height, radius: 16, outlined: true
    }) if @bgimg.nil?
    @bgimg.draw(screen_x, screen_y, @z, 1.0, 1.0, color)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop for button behaviors.
  def update()
    return unless super()
    if @action_timeout > 0
      @is_highlighted = false
      @action_timeout -= 1
      return     
    end
    mouse_hover?()
    if @has_actioned
      @is_highlighted = false
      unless $controls.holding?(:mouse_lclick)
        @has_actioned = false
        @is_depresed = false
      end
    else
      if @is_highlighted
        if @is_depresed
          unless $controls.holding?(:mouse_lclick)
            action()
          end
        elsif $controls.trigger?(:mouse_lclick)
          @is_depresed = true 
        end
      else
        @is_depresed = false
      end
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return unless super()
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
    @font.draw_text(@text, screen_x, screen_y, @z+1, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @bgimg = nil
    super()
  end
end
