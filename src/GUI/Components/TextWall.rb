#===============================================================================================================================
# !!!  TextWall.rb |  An on screen interactive object that displays a large amount of text.
#===============================================================================================================================
class GUI::TextWall < GUI::Component
  attr_accessor :text, :font
  #---------------------------------------------------------------------------------------------------------
  #D: Creates the Kernel Class (klass) instance.
  def initialize(options = {})
    @text = options[:text] || ''
    font_size = options[:font_size] || 24
    @font = Gosu::Font.new($application, "verdana", font_size)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Update loop, where things get up to date!
  def update
    return unless super()

  end
  #---------------------------------------------------------------------------------------------------------
  # Draw to screen.
  def draw
    return unless super()
    @font.draw_text(@text, @x, @y, @z+1, 1, 1, 0xFF_ffffff)
  end

  #---------------------------------------------------------------------------------------------------------
  #D: Called when the button is disposed and/or when the parent class is destroyed.
  def dispose()
    super()
  end
end