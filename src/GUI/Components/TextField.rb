#===============================================================================================================================
# !!!  TextField.rb |  An on screen interactive object that accepts keyboard input.
#===============================================================================================================================
# Escape key will not be 'eaten' by text fields; use for de-activating.
# Tab key will not be 'eaten' by text fields; use for switching
#===============================================================================================================================
class GUI::TextField < GUI::Component
  BLINK_SPEED = 20
  REPEAT_PRESS_TIMEOUT = 0
  MAX_LENGTH = 42 # 128
  SELECTION_COLOR = 0xcc_0000ff
  CARET_COLOR = 0xff_ffffff

  attr_accessor :font
  #---------------------------------------------------------------------------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(options = {})
    super(options)
    @place_hold_text = options[:text] || ''
    font_size = options[:font_size] || 24
    @font   = Gosu::Font.new($application, "verdana", font_size)
    @height = options[:height] || font_size * 2
    @box_edge_buf = font_size / 2 #DV Add a little to the box so not touching text on edges.
    @is_active = true  #DV Allow the text field to be changed?
    @pulse = [0, true] #DV Used to blink the text position.
    @press_repeat = REPEAT_PRESS_TIMEOUT
    @bgcolor = 0xff_353535 #DV Background color used to fill viewing Rect.
    # setup call method for action
    if @owner.nil?
      print("Error with TextField no owner, skipping")
      return nil
    end
    @action = options[:action] || nil
    is_ready()
  end
  #---------------------------------------------------------------------------------------------------------
  def text()
    return @textInput.text
  end
  #---------------------------------------------------------------------------------------------------------
  #D Set Gosu window to TextInput active for keyboard input with text.
  def is_ready()
    @textInput = Gosu::TextInput.new()
    @textInput.text = @place_hold_text
    $application.text_input = @textInput
    super()
  end
  #---------------------------------------------------------------------------------------------------------
  #D Try first to catch errors, and call function from parent class user.
  def action()
    if @action.nil?
      print("There is an error with TextField\n In: #{@owner}")
      return false
    end
    # use owner class for method call
    test = @owner.send(@action, @textInput.text) || nil
    if test.nil?
      return false if @disposed 
      Logger.warn("TextField", "Callback method '#{@action}' in #{@owner} needs to return true unless error.",
        tags: [:GUI]
      )
      return false
    end
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  def draw_background(screen_x, screen_y, color)
    @bgimg = GUI::BlobDraw.get_image({
      of: :round_rect, width: @width, height: @height, radius: 8, outlined: true
    }) if @bgimg.nil?
    @bgimg.draw(screen_x, screen_y, @z, 1.0, 1.0, color)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop for button behaviors.
  def update()
    return unless super()
    # special character control checks for input from keyboard when TextInput is active
    if $controls.trigger?(:esc, true)
      $application.text_input = nil
    elsif @textInput.text.length > 0 && $controls.trigger?(:return, true)
      action()
      @textInput.text = ''
    end
    # when clicked on, activate TextInput if not already active and reading text
    if $controls.trigger?(:l_clk, true)
      if $application.text_input != @textInput && under_mouse?
        $application.text_input = @textInput
      else
        $application.text_input = nil
      end
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Tries to move the caret to the position specifies by mouse_x
  def move_caret_to_mouse
    # Test character by character
    1.upto(self.text.length) do |i|
      if $application.mouse_x < x + @font.text_width(text[0...i])
        @textInput.caret_pos = @textInput.selection_start = i - 1
        return
      end
    end
    # Default case: user must have clicked the right edge
    @textInput.caret_pos = @textInput.selection_start = @textInput.text.length
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return unless super()
    draw_background(@x, @y, @bgcolor)
    # show what has been typed already
    # Calculate the position of the caret and the selection start.
    pos_x = @x + @box_edge_buf + @font.text_width(@textInput.text[0...@textInput.caret_pos])
    sel_x = @x + @box_edge_buf + @font.text_width(@textInput.text[0...@textInput.selection_start])
    sel_w = pos_x - sel_x
    Gosu.draw_rect(sel_x, @y, sel_w, @height, SELECTION_COLOR, z)
    if $application.text_input == @textInput
      if @pulse[0] > 0 
        @pulse[0] -= 1
      else
        @pulse[0] = BLINK_SPEED
        @pulse[1] = !@pulse[1]
      end
      if @pulse[1]
        Gosu.draw_line(pos_x, @y + @box_edge_buf, CARET_COLOR,
          pos_x, @y + @height - @box_edge_buf, CARET_COLOR, @z + 1
        )
      end
    end
    @font.draw_text(@textInput.text, @x + @box_edge_buf, @y + @box_edge_buf, @z+1, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @bgimg = nil
    if $application.text_input == @textInput
      $application.text_input = nil
    end
    super()
  end
end
