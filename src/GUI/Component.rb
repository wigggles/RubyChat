#=====================================================================================================================
# !!!  Component.rb |  An on screen interactive GUI input object for Gosu window based applications.
#=====================================================================================================================
# Base GUI interactive object parent class is this Component defined object.
#=====================================================================================================================
class GUI; end

#=====================================================================================================================
class GUI::Component
  attr_accessor :active, :x, :y, :z, :width, :height, :color
  attr_reader :owner

  #--------------------------------------
  # Creates the Kernel Class (klass) instance.
  def initialize(options = nil, width: 0, height: 0, pos_x: 0, pos_y: 0, pos_z: 0, owner: nil)
    if options
      @height = options.fetch(:height, 0)
      @width  = options.fetch(:width, 0)
      @x = options.fetch(:pos_x, 0)
      @y = options.fetch(:pos_y, 0)
      @z = options.fetch(:pos_z, 0)
      @owner = options.fetch(:owner, nil)
    else
      @height = height
      @width  = width
      @x = pos_x
      @y = pos_y
      @z = pos_z
      @owner = owner
    end
  end

  #--------------------------------------
  # Called from child class after initialization.
  def flag_as_ready
    @disposed = false
    @active = true
  end

  #--------------------------------------
  # Check if the component is under the mouse cursor.
  def under_mouse?
    $application.mouse_x > @x &&
      $application.mouse_x < @x + @width &&
      $application.mouse_y > @y &&
      $application.mouse_y < @y + @height
  end

  #--------------------------------------
  def bottom
    @y + @height
  end

  #--------------------------------------
  def right
    @x + @width
  end

  #--------------------------------------
  # Update loop for button behaviors.
  def update
    return false if @disposed || $application.nil? || !@active

    true
  end

  #--------------------------------------
  # Draw onto the Gosu window any images related to the button.
  def draw
    return false if @disposed || $application.nil?

    true
  end

  #--------------------------------------
  # Called when the button is disposed and/or when the parent class is destroyed.
  def dispose
    @disposed = true
  end

  #--------------------------------------
  def disposed?
    @disposed
  end
end
