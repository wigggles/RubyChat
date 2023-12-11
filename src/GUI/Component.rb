#===============================================================================================================================
# !!!  Component.rb |  An on screen interactive GUI input object for Gosu window based applications.
#===============================================================================================================================
module GUI
  @@parent_window = nil
  #---------------------------------------------------------------------------------------------------------
  def self.bind_window(parent_window)
    @@parent_window = parent_window
  end
  #---------------------------------------------------------------------------------------------------------
  def self.parent_window()
    return @@parent_window
  end
end
#===============================================================================================================================
# Base GUI interactive object parent class is this Component defined object.
#===============================================================================================================================
class GUI::Component
  attr_accessor :active, :x, :y, :z, :width, :height, :color
  #--------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(options = {})
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
    return false if @disposed || GUI.parent_window.nil? || !@active
    return true
  end
  #--------------------------------------
  #D: Draw onto the Gosu window any images related to the button.
  def draw()
    return false if @disposed || GUI.parent_window.nil?
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
