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
  def initialize(options = {})
    @width  = options[:width]  || 0  #DV Width of the viewing Rect.
    @height = options[:height] || 0  #DV Height of the viewing Rect.
    @x = options[:x] || 0
    @y = options[:y] || 0
    @z = options[:z] || 0
    @owner = options[:owner] || nil
  end
  #--------------------------------------
  #D: Called from child class after initilization.
  def is_ready
    @disposed = false
    @active = true
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
