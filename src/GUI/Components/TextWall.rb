#=====================================================================================================================
# !!!  TextWall.rb |  An on screen interactive object that displays a large amount of text.
#=====================================================================================================================
class GUI::TextWall < GUI::Component
  attr_accessor :text, :font

  #---------------------------------------------------------------------------------------------------------
  # Creates the Kernel Class (klass) instance.
  def initialize(text: '', font_size: 24, **supers)
    super(supers)
    @text = text
    # @font = Gosu::Font.new($application, "verdana", font_size)
    @text_image = Gosu::Image.from_markup(@text, font_size, width: @width)
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop, where things get up to date!
  def update
    nil unless super()
  end

  #---------------------------------------------------------------------------------------------------------
  # Draw to screen.
  def draw
    return unless super()

    # @font.draw_text(@text, @x, @y, @z+1, 1, 1, 0xFF_ffffff)
    @text_image.draw(@x, @y, @z)
  end

  #---------------------------------------------------------------------------------------------------------
  # Called when the button is disposed and/or when the parent class is destroyed.
  def dispose
    @text_image = nil
    super()
  end
end
