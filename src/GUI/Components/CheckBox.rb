#=====================================================================================================================
# !!!  CheckBox.rb |  Click taggable interactive input GUI object for Gosu window based applications.
#=====================================================================================================================
class GUI::CheckBox < GUI::Button
  attr_accessor :toggled

  #---------------------------------------------------------------------------------------------------------
  # Creates the Kernel Class (klass) instance.
  def initialize(radius: 12, toggled: false, scolor: Gosu::Color.argb(0xff_ff8866), **supers)
    super(supers)
    @radius = radius
    @width  = supers[:width]  || @radius * 2 || 24
    @height = supers[:height] || @radius * 2 || 24
    @toggled = toggled
    @scolor  = scolor
    flag_as_ready
  end

  #---------------------------------------------------------------------------------------------------------
  # D Try first to catch errors, and call function from parent class user.
  def action
    return false unless @is_highlighted
    return true if @has_actioned

    if @action.nil?
      Logger.error('CheckBox', "Callback method for @action in #{@owner} is not set.",
                   tags: [:GUI])
      return false
    end
    # use owner class for method call
    @toggled = !@toggled
    test = @owner.send(@action, @toggled) || nil
    if test.nil?
      return false if @disposed

      Logger.warn('CheckBox', "Callback method '#{@action}' in #{@owner} needs to return true unless error.",
                  tags: [:GUI])
      return false
    end
    @has_actioned = true
    @action_timeout = GUI::Button::ACTION_TIMEOUT
    true
  end

  #---------------------------------------------------------------------------------------------------------
  def draw_background(screen_x, screen_y, color)
    if @bgimg.nil?
      @bgimg = GUI::BlobDraw.get_image(
        of_type: :circle, radius: @radius, outlined: true, thickness: 3
      )
    end
    @bgimg.draw(screen_x, screen_y, @z, 1.0, 1.0, color)
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop for button behaviors.
  def update
    nil unless super()
  end

  #---------------------------------------------------------------------------------------------------------
  # Draw onto the Gosu window any images related to the button.
  def draw
    return if @disposed || $application.nil?

    color = (if @is_highlighted
               @hcolor
             else
               (@toggled ? @scolor : @color)
             end)
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
  end

  #---------------------------------------------------------------------------------------------------------
  # Called when the button is disposed and/or when the parent class is destroyed.
  def dispose
    @bgimg = nil
    super()
  end
end
