#===============================================================================================================================
# !!!  BlobDraw.rb |  Draw extended shapes and cache the pixles into an image blob for drawing later.
#===============================================================================================================================
module BlobDraw
  SOLID_PIXEL = 0xff.chr()
  CLEAR_PIXEL = 0x00.chr()
  # Color is not set here out side of gray scale. The main color is set when the cached blob image is drawn.
  OUTLINE_COLOR = 0xFF_ffffff
  FILL_COLOR    = 0xFF_cccccc
  #---------------------------------------------------------------------------------------------------------
  # Fetch an image that is known how to be drawn.
  def self.get_image(options = {})
    width     = options[:width]     || 50          # Image width.
    height    = options[:height]    || 50          # Image height.
    of_type   = options[:of]        || :circle     # What shape/item to draw.
    filled    = options[:filled]    || true        # If not filled, then show only outline.
    outlined  = options[:outlined]  || false       # Show outline when filled.
    thickness = options[:thickness] || 4           # Outline size.
    #--------------------------------------
    # after looking at the options, get the requested blob for drawing
    case of_type
    when :rectangle
      if !filled

      elsif outlined
        outline = Gosu::Image.new(Rectangle.new(options))
        options[:width]  -= (thickness * 2)
        options[:height] -= (thickness * 2)
        fill    = Gosu::Image.new(Rectangle.new(options))
        image_blob ||= Gosu::render(width, height, retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, BlobDraw::OUTLINE_COLOR)
          fill.draw(thickness, thickness, 0, 1.0, 1.0, BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(Rectangle.new(options))
      end
    #--------------------------------------
    when :round_rect
      if !filled

      elsif outlined
        outline = Gosu::Image.new(RoundRectangle.new(options))
        options[:width]  -= (thickness * 2)
        options[:height] -= (thickness * 2)
        fill    = Gosu::Image.new(RoundRectangle.new(options))
        image_blob ||= Gosu::render(width, height, retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, BlobDraw::OUTLINE_COLOR)
          fill.draw(thickness, thickness, 0, 1.0, 1.0, BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(RoundRectangle.new(options))
      end
    #--------------------------------------
    when :circle
      if !filled

      elsif outlined
        outline = Gosu::Image.new(Circle.new(options))
        options[:width]  -= (thickness * 2)
        options[:height] -= (thickness * 2)
        fill    = Gosu::Image.new(Circle.new(options))
        image_blob ||= Gosu::render(width, height, retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, BlobDraw::OUTLINE_COLOR)
          fill.draw(thickness, thickness, 0, 1.0, 1.0, BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(Circle.new(options))
      end
    else
      Logger.error("BlobDraw", "Does not know how to draw a (#{of_type})")
    end
  end
  #---------------------------------------------------------------------------------------------------------
  # How to draw a rectangle with square corners.
  class Rectangle
    attr_reader :columns, :rows
    def initialize(options = {})
      @columns = options[:width]  ||  50
      @rows    = options[:height] || 100
      lower_half = (0...(@rows / 2)).map() { |y|
        right_half = "#{BlobDraw::SOLID_PIXEL * (@columns / 2)}"
        right_half.reverse + right_half
      }.join()
      alpha_channel = lower_half.reverse + lower_half
      @blob = alpha_channel.gsub(/./) { |alpha| BlobDraw::SOLID_PIXEL * 3 + alpha }
    end
    def to_blob(); @blob; end
  end
  #---------------------------------------------------------------------------------------------------------
  # How to draw a rectangle with rounded corners.
  class RoundRectangle
    attr_reader :columns, :rows
    def initialize(options = {})
      puts(options.inspect)
      @columns =   options[:width]  || 100
      @rows    =   options[:height] ||  50
      radius   = [[options[:radius] ||  12, 2].max(), @rows].min()
      top_half = (0...(@rows / 2)).map() { |y|
        x = @columns / 2
        r = (y < radius ? radius - Math.sqrt((radius ** 2) - ((radius - y) ** 2)).round() : 0)
        r = radius - 2 if r >= radius
        left_half = "#{BlobDraw::CLEAR_PIXEL * r}#{BlobDraw::SOLID_PIXEL * (x - r)}"
        left_half + left_half.reverse
      }.join()
      alpha_channel = top_half + top_half.reverse
      @blob = alpha_channel.gsub(/./) { |alpha| BlobDraw::SOLID_PIXEL * 3 + alpha }
    end
    def to_blob(); @blob; end
  end
  #---------------------------------------------------------------------------------------------------------
  # How to draw a circle.
  class Circle
    attr_reader :columns, :rows
    def initialize(options = {})
      radius = options[:radius] || 50
      @columns = @rows = radius * 2
      lower_half = (0...radius).map() { |y|
        x = Math.sqrt(radius ** 2 - y ** 2).round()
        right_half = "#{BlobDraw::SOLID_PIXEL * x}#{BlobDraw::CLEAR_PIXEL * (radius - x)}"
        right_half.reverse + right_half
      }.join()
      alpha_channel = lower_half.reverse + lower_half
      @blob = alpha_channel.gsub(/./) { |alpha| BlobDraw::SOLID_PIXEL * 3 + alpha }
    end
    def to_blob(); @blob; end
  end
end
