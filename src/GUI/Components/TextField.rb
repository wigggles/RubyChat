#===============================================================================================================================
# !!!  TextField.rb |  An on screen interactive object that accepts keyboard input.
#===============================================================================================================================
class TextField
  BLINK_SPEED = 20
  REPEAT_PRESS_TIMEOUT = 10
  MAX_LENGTH = 42 # 128
  @@parent_window = nil

  attr_accessor :is_active, :x, :y, :z, :color, :text, :font
  #---------------------------------------------------------------------------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(parent_window, options = {})
    @@parent_window = parent_window
    @x = options[:x] || 0
    @y = options[:y] || 0
    @text = options[:text] || ''
    font_size = options[:font_size] || 24
    @font   = Gosu::Font.new(@@parent_window, "verdana", font_size)
    @width  = options[:width] || 0
    @height = options[:height] || font_size * 2
    @box_edge_buf = font_size / 2 #DV Add a little to the box so not touching text on edges.
    @is_active = true  #DV Allow the text field to be changed?
    @pulse = [0, true] #DV Used to blink the text position.
    @press_repeat = REPEAT_PRESS_TIMEOUT
    @bgcolor = 0xff_353535 #DV Background color used to fill viewing Rect.
    # setup call method for action
    @owner = options[:owner] || nil
    if @owner.nil?
      print("Error with TextField no owner, skipping")
      return nil
    end
    @action = options[:action] || nil
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop for button behaviors.
  def update()
    return if @disposed || @@parent_window.nil?
    return unless @is_active
    @press_repeat -= 1 if @press_repeat > 0
    @old_key_press = nil if @press_repeat <= 0
    # when accepting key inputs
    if @@parent_window.controls.grab_characters != @old_key_press
      @press_repeat = REPEAT_PRESS_TIMEOUT
      @old_key_press = @@parent_window.controls.grab_characters
      if @pulse[1]
        @text.chop! # remove last character
        @pulse = [BLINK_SPEED, false] # reset pulse active bar
      end
      # update text field base on last input action
      case @old_key_press
      when 'backspace' then @text.chop! # remove last character
      when 'del' then @text = ''        # clear all text
      when 'tab' then @text += ''
      when 'space' then @text += ' ' if @text.length < MAX_LENGTH
      when 'return'                     # call action with text value
        if @text.length > 0
          action()
          @text = ''
        end
      else # add letter character string to text value
        return if @text.length > MAX_LENGTH - 1
        @text += @old_key_press.to_s
      end
    end
    #--------------------------------------
    if @pulse[0] > 0 
      @pulse[0] -= 1
    else
      @pulse[0] = BLINK_SPEED
      if @pulse[1]
        @text.chop! # remove last character
      else
        @text += "|"
      end
      @pulse[1] = !@pulse[1]
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return if @disposed || @@parent_window.nil?
    draw_background(@x, @y, @bgcolor)
    # show what has been typed already
    @font.draw_text(@text, @x + @box_edge_buf, @y + @box_edge_buf, 0, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  def draw_background(screen_x, screen_y, color)
    #@@parent_window.draw_rect(@x, @y, @width, @height, 0xff_353535)
    @bgimg = BlobDraw.get_image({
      of: :round_rect, width: @width, height: @height, radius: 8, outlined: true
    }) if @bgimg.nil?
    @bgimg.draw(screen_x, screen_y, 0, 1.0, 1.0, color)
  end
  #---------------------------------------------------------------------------------------------------------
  #D Try first to catch errors, and call function from parent class user.
  def action()
    if @action.nil?
      print("There is an error with TextField\n In: #{@owner}")
      return false
    end
    # use owner class for method call
    test = @owner.send(@action, @text) || nil
    if test.nil?
      return false if @disposed 
      Logger.error("TextField", "Callback method '#{@action}' in #{@owner} needs to return true.")
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
