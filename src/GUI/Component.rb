#===============================================================================================================================
# !!!  Component.rb |  An on screen interactive GUI input object for Gosu window based applications.
#===============================================================================================================================
# Base GUI interactive object parent class is this Component defined object.
#===============================================================================================================================
class GUI; end
#===============================================================================================================================
class GUI::Component
  attr_accessor :active, :x, :y, :z, :width, :height, :color
  attr_reader :owner
  #--------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(
    options = nil,
    width: 0, height: 0,
    x: 0, y: 0, z: 0,
    owner: nil
  )
    if options
      @height = options.fetch(:height, 0)
      @width  = options.fetch(:width, 0)
      @x = options.fetch(:x, 0)
      @y = options.fetch(:y, 0)
      @z = options.fetch(:z, 0)
      @owner = options.fetch(:owner, nil)
    else
      @height = height
      @width  = width
      @x = x
      @y = y
      @z = z
      @owner = owner
    end
  end
  #--------------------------------------
  #D: Called from child class after initialization.
  def is_ready
    @disposed = false
    @active = true
  end
  #--------------------------------------
  #D: Check if the component is under the mouse cursor.
  def under_mouse?
    return (
      $application.mouse_x > @x &&
      $application.mouse_x < @x + @width &&
      $application.mouse_y > @y &&
      $application.mouse_y < @y + @height
    )
  end
  #--------------------------------------
  def bottom()
    return @y + @height
  end
  #--------------------------------------
  def right()
    return @x + @width
  end
  #--------------------------------------
  #D: Update loop for button behaviors.
  def update()
    return false if @disposed || $application.nil? || !@active
    return true
  end
  #--------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return false if @disposed || $application.nil?
    return true
  end
  #--------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    @disposed = true
  end
  #--------------------------------------
  def disposed?
    return @disposed
  end
end
