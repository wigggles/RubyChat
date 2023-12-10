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
  def self.get_image(opt = {})
    opt[:width]     = opt[:width]      ||   50        # Image width.
    opt[:height]    = opt[:height]     ||   50        # Image height.
    opt[:of_type]   = opt[:of]         || :circle     # What shape/item to draw.
    opt[:radius]    = opt[:radius]     ||   50        # How round to draw edges.
    opt[:outlined]  = opt[:outlined]   ||  false      # Show outline when filled.
    opt[:outline]   = opt[:outline]    ||  false      # Only outline, do not fill.
    opt[:thickness] = opt[:thickness]  ||    4        # Outline size.
    #--------------------------------------
    # only works with even blobs, so that gets checked and patched here
    opt[:width]  += 1 if (opt[:width]  % 2) != 0
    opt[:height] += 1 if (opt[:height] % 2) != 0
    #--------------------------------------
    # after looking at the opt, get the requested blob for drawing
    case opt[:of_type]
    when :rectangle
      if opt[:outline]
        return Gosu::Image.new(Rectangle.new(opt))
      elsif opt[:outlined]
        outline = Gosu::Image.new(Rectangle.new(opt))
        opt[:width]  -= (opt[:thickness] * 2)
        opt[:height] -= (opt[:thickness] * 2)
        fill = Gosu::Image.new(Rectangle.new(opt))
        opt[:width]  += (opt[:thickness] * 2)
        opt[:height] += (opt[:thickness] * 2)
        image_blob ||= Gosu::render(opt[:width], opt[:height], retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, BlobDraw::OUTLINE_COLOR)
          fill.draw(opt[:thickness], opt[:thickness], 0, 1.0, 1.0, BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(Rectangle.new(opt))
      end
    #--------------------------------------
    when :round_rect
      if opt[:outline]
        return Gosu::Image.new(RoundRectangle.new(opt))
      elsif opt[:outlined]
        outline = Gosu::Image.new(RoundRectangle.new(opt))
        opt[:width]  -= (opt[:thickness] * 2)
        opt[:height] -= (opt[:thickness] * 2)
        fill = Gosu::Image.new(RoundRectangle.new(opt))
        opt[:width]  += (opt[:thickness] * 2)
        opt[:height] += (opt[:thickness] * 2)
        image_blob ||= Gosu::render(opt[:width], opt[:height], retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, BlobDraw::OUTLINE_COLOR)
          fill.draw(opt[:thickness], opt[:thickness], 0, 1.0, 1.0, BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(RoundRectangle.new(opt))
      end
    #--------------------------------------
    when :circle
      if opt[:outline]
        return Gosu::Image.new(Circle.new(opt))
      elsif opt[:outlined]
        outline = Gosu::Image.new(Circle.new(opt))
        opt[:width]  -= (opt[:thickness] * 2)
        opt[:height] -= (opt[:thickness] * 2)
        fill = Gosu::Image.new(Circle.new(opt))
        opt[:width]  += (opt[:thickness] * 2)
        opt[:height] += (opt[:thickness] * 2)
        image_blob ||= Gosu::render(opt[:width], opt[:height], retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, BlobDraw::OUTLINE_COLOR)
          fill.draw(opt[:thickness], opt[:thickness], 0, 1.0, 1.0, BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(Circle.new(opt))
      end
    else
      Logger.error("BlobDraw", "Does not know how to draw a (#{of_type})")
    end
  end
  #---------------------------------------------------------------------------------------------------------
  # How to draw a rectangle with square corners.
  class Rectangle
    attr_reader :columns, :rows
    def initialize(opt = {})
      @columns = opt[:width]
      @rows    = opt[:height]
      # start drawing
      lower_half = (0...(@rows / 2)).map() { |y|
        if opt[:outline]
          x = @columns / 2
          x_skip = y > opt[:thickness] ? opt[:thickness] : x
          right_half = "#{BlobDraw::CLEAR_PIXEL * (x - x_skip)}#{BlobDraw::SOLID_PIXEL * x_skip}"
        else
          right_half = "#{BlobDraw::SOLID_PIXEL * (@columns / 2)}"
        end
        right_half.reverse + right_half
      }.join()
      alpha_channel = lower_half + lower_half.reverse
      @blob = alpha_channel.gsub(/./) { |alpha| BlobDraw::SOLID_PIXEL * 3 + alpha }
    end
    def to_blob(); @blob; end
  end
  #---------------------------------------------------------------------------------------------------------
  # How to draw a rectangle with rounded corners.
  class RoundRectangle
    attr_reader :columns, :rows
    def initialize(opt = {})
      puts(opt.inspect)
      @columns = opt[:width]
      @rows    = opt[:height]
      radius   = [[opt[:radius], 2].max(), @rows].min()
      # start drawing
      top_half = (0...(@rows / 2)).map() { |y|
        x = @columns / 2
        r = (y < radius ? radius - Math.sqrt((radius ** 2) - ((radius - y) ** 2)).round() : 0)
        r = radius - 2 if r >= radius
        if opt[:outline]
          x_skip = y > opt[:thickness] ? opt[:thickness] : x - r
          left_half = "#{BlobDraw::CLEAR_PIXEL * r}#{BlobDraw::SOLID_PIXEL * x_skip}#{BlobDraw::CLEAR_PIXEL * (x - x_skip - r)}"
        else
          left_half = "#{BlobDraw::CLEAR_PIXEL * r}#{BlobDraw::SOLID_PIXEL * (x - r)}"
        end
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
    def initialize(opt = {})
      radius = opt[:radius]
      @columns = @rows = radius * 2
      # start drawing
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
