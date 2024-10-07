#===============================================================================================================================
# !!!  CheckBox.rb |  Click taggable interactive input GUI object for Gosu window based applications.
#===============================================================================================================================
class GUI::CheckBox < GUI::Button
  attr_accessor :toggled
  #---------------------------------------------------------------------------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(options = {})
    super(options)
    @radius = options[:radius] || 12
    @width  = options[:width]  || @radius * 2 || 24
    @height = options[:height] || @radius * 2 || 24
    @toggled = options[:toggled] || false
    @scolor  = options[:scolor]  || Gosu::Color.argb(0xff_ff8866)
    is_ready()
  end
  #---------------------------------------------------------------------------------------------------------
  #D Try first to catch errors, and call function from parent class user.
  def action()
    return false unless @is_highlighted
    return true if @has_actioned
    if @action.nil?
      print("There is an error with checkbox\n In: #{@owner}")
      return false
    end
    # use owner class for method call
    @toggled = !@toggled
    test = @owner.send(@action, @toggled) || nil
    if test.nil?
      return false if @disposed
      Logger.warn("CheckBox", "Callback method '#{@action}' in #{@owner} needs to return true unless error.",
        tags: [:GUI]
      )
      return false
    end
    @has_actioned = true
    @action_timeout = GUI::Button::ACTION_TIMEOUT
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  def draw_background(screen_x, screen_y, color)
    @bgimg = GUI::BlobDraw.get_image({of: :circle, radius: @radius, outlined: true}) if @bgimg.nil?
    @bgimg.draw(screen_x, screen_y, @z, 1.0, 1.0, color)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop for button behaviors.
  def update()
    return unless super()

  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return if @disposed || $application.nil?
    color = (@is_highlighted ? @hcolor : (@toggled ? @scolor : @color))
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
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @bgimg = nil
    super()
  end
end
