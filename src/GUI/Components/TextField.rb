#===============================================================================================================================
# !!!  TextField.rb |  An on screen interactive object that accepts keyboard input.
#===============================================================================================================================
# Escape key will be 'eaten' by Gosu::TextInput when one is active. Use for de-activating.
# 
#===============================================================================================================================
class GUI::TextField < GUI::Component
  #===============================================================================================================================
  BLINK_SPEED = 20

  attr_accessor :font, :max_length
  #---------------------------------------------------------------------------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(
    text: '',
    font_size: 24,
    max_length: :auto,
    max_width: :auto,
    action: nil,
    regex_accept: nil,
    regex_reject: nil,
    **supers # send the rest of the keyword arguments into parent constructor klass
  ); super(supers)
    @font   = Gosu::Font.new($application, "verdana", font_size)
    @max_length = max_length
    @max_width = max_width
    @height = (font_size * 2) if supers[:height].nil? || (supers[:height] < 1)
    @place_hold_text = text
    @box_edge_buf = font_size / 2 #DV Add a little to the box so not touching text on edges.
    @is_active = true             #DV Allow the text field to be changed?
    @pulse = [0, true]            #DV Used to blink the text position.
    @bgcolor = 0xff_353535        #DV Background color used to fill viewing Rect.
    @ccolor  = 0xff_ffffff        #DV Caret color.
    @scolor  = 0xcc_0000ff        #DV Text selected background color.
    @regex_accept = regex_accept
    @regex_reject = regex_reject
    # setup call method for action
    if @owner.nil?
      print("Error with TextField no owner, skipping")
      return nil
    end
    @action = action
    is_ready()
  end
  #---------------------------------------------------------------------------------------------------------
  def text()
    return @textInput.text
  end
  #---------------------------------------------------------------------------------------------------------
  #D Set Gosu window to TextInput active for keyboard input with text.
  def is_ready()
    return unless @textInput.nil?
    if @max_width == :auto
      @max_width = @width - (@box_edge_buf * 3)
    end
    @textInput = GUI::TextField::TextFilter.new(
      font: @font, max_length: @max_length, max_width: @max_width,
      regex_accept: @regex_accept, regex_reject: @regex_reject
    )
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
    @bgimg = GUI::BlobDraw.get_image(
      of_type: :round_rect, width: @width, height: @height, radius: 8, outlined: true
    ) if @bgimg.nil?
    @bgimg.draw(screen_x, screen_y, @z, 1.0, 1.0, color)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop for button behaviors.
  def update()
    return unless super()
    # special character control checks for input from keyboard when a Gosu::TextInput is active
    if $controls.trigger?(:esc, true)
      $application.text_input = nil
    elsif @textInput.text.length > 0 && $controls.trigger?(:return, true)
      action()
      @textInput.text = ''
    end
    # when clicked on, activate TextInput if not already active and reading text
    if $controls.trigger?(:l_clk, true)
      mouse_is_overtop = under_mouse?
      if ($application.text_input != @textInput && mouse_is_overtop)
        $application.text_input = @textInput
      elsif ($application.text_input == @textInput && mouse_is_overtop)
        move_caret_to_mouse()
      else
        $application.text_input = nil
      end
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Tries to move the caret to the position specifies by mouse_x, *from Gosu example.
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
    # calculate the position of the caret and the selection start.
    caret_pos_x = @x + @box_edge_buf + @font.text_width(@textInput.text[0...@textInput.caret_pos])
    unless @scolor.nil?
      sel_x = @x + @box_edge_buf + @font.text_width(@textInput.text[0...@textInput.selection_start])
      Gosu.draw_rect(sel_x, @y, caret_pos_x - sel_x, @height, @scolor, @z)
    end
    # draw the current curet position for editing.
    unless @ccolor.nil?
      if $application.text_input == @textInput
        if @pulse[0] > 0
          @pulse[0] -= 1
        else
          @pulse[0] = BLINK_SPEED
          @pulse[1] = !@pulse[1]
        end
        if @pulse[1]
          Gosu.draw_line(caret_pos_x, @y + @box_edge_buf, @ccolor,
            caret_pos_x, @y + @height - @box_edge_buf, @ccolor, @z + 1
          )
        end
      end
    end
    # show what has been typed already
    @font.draw_text(@textInput.text, @x + @box_edge_buf, @y + @box_edge_buf, @z+1, 1, 1, 0xFF_ffffff)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @bgimg = nil
    if $application.text_input == @textInput
      $application.text_input = nil
    end
    @textInput = nil
    super()
  end
end

#===============================================================================================================================
# !!!  TextField::TextFilter.rb |  Gosu::TextInput interactive object with a filter method for regex.
#===============================================================================================================================
# https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html
# https://ruby-doc.org/3.3.5/MatchData.html
#===============================================================================================================================
class GUI::TextField::TextFilter < Gosu::TextInput
  attr_reader :regex_accept, :regex_reject, :max_length, :max_width, :font
  #---------------------------------------------------------------------------------------------------------
  def initialize(max_length: 128, max_width: nil, regex_accept: nil, regex_reject: nil, font: nil)
    @regex_accept = regex_accept
    @regex_reject = regex_reject
    @max_length = max_length      #DV If using :auto instead of a text character length, font is required with max_width.
    @text_font = font             #DV A font is required when utilizing the auto width functionality.
    @max_width = max_width        #DV Sets max with in pixels based on the font provided.
    super()
  end
  #---------------------------------------------------------------------------------------------------------
  def filter(text_in)
    allowed_length = @max_length
    if (@max_length == :auto && !@max_width.nil?)
      return '' if @text_font.text_width(text) > @max_width.floor()
    elsif @max_length.is_a?(Integer)
      allowed_length = [@max_length - text.length, 0].max()
      text_in = text_in[0, allowed_length]
    end
    if (!@regex_accept.nil? && text_in.match?(@regex_accept))
      text_in = @regex_accept.match(text_in)[1]
    end
    text_in.upcase.gsub(@regex_reject, '') unless @regex_reject.nil?
    return text_in
  end
end
