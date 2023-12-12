#===============================================================================================================================
# !!!  BlobDraw.rb |  Draw extended shapes and cache the pixles into an image blob for drawing later.
#===============================================================================================================================
module GUI::BlobDraw
  SP = 0xff.chr() # Solid Pixel
  CP = 0x00.chr() # Clear pixel
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
        return Gosu::Image.new(GUI::BlobDraw::Rectangle.new(opt))
      elsif opt[:outlined]
        outline = Gosu::Image.new(GUI::BlobDraw::Rectangle.new(opt))
        opt[:width]  -= (opt[:thickness] * 2)
        opt[:height] -= (opt[:thickness] * 2)
        fill = Gosu::Image.new(GUI::BlobDraw::Rectangle.new(opt))
        opt[:width]  += (opt[:thickness] * 2)
        opt[:height] += (opt[:thickness] * 2)
        image_blob ||= Gosu::render(opt[:width], opt[:height], retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, GUI::BlobDraw::OUTLINE_COLOR)
          fill.draw(opt[:thickness], opt[:thickness], 0, 1.0, 1.0, GUI::BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(GUI::BlobDraw::Rectangle.new(opt))
      end
    #--------------------------------------
    when :round_rect
      if opt[:outline]
        return Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(opt))
      elsif opt[:outlined]
        outline = Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(opt))
        opt[:width]  -= (opt[:thickness] * 2)
        opt[:height] -= (opt[:thickness] * 2)
        fill = Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(opt))
        opt[:width]  += (opt[:thickness] * 2)
        opt[:height] += (opt[:thickness] * 2)
        image_blob ||= Gosu::render(opt[:width], opt[:height], retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, GUI::BlobDraw::OUTLINE_COLOR)
          fill.draw(opt[:thickness], opt[:thickness], 0, 1.0, 1.0, GUI::BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(opt))
      end
    #--------------------------------------
    when :circle
      opt[:width]  = opt[:radius] * 2
      opt[:height] = opt[:radius] * 2
      if opt[:outline]
        return Gosu::Image.new(GUI::BlobDraw::Circle.new(opt))
      elsif opt[:outlined]
        outline = Gosu::Image.new(GUI::BlobDraw::Circle.new(opt))
        opt[:radius] -= opt[:thickness]
        fill = Gosu::Image.new(GUI::BlobDraw::Circle.new(opt))
        image_blob ||= Gosu::render(opt[:width], opt[:height], retro: true) do 
          outline.draw(0, 0, 0, 1.0, 1.0, GUI::BlobDraw::OUTLINE_COLOR)
          fill.draw(opt[:thickness], opt[:thickness], 0, 1.0, 1.0, GUI::BlobDraw::FILL_COLOR)
        end
        return image_blob
      else
        return Gosu::Image.new(GUI::BlobDraw::Circle.new(opt))
      end
    else
      Logger.error("BlobDraw", "Does not know how to draw a (#{of_type})",
        tags: [:GUI]
      )
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
          right_half = "#{GUI::BlobDraw::CP * (x - x_skip)}#{GUI::BlobDraw::SP * x_skip}"
        else
          right_half = "#{GUI::BlobDraw::SP * (@columns / 2)}"
        end
        right_half.reverse + right_half
      }.join()
      alpha_channel = lower_half + lower_half.reverse
      @blob = alpha_channel.gsub(/./) { |alpha| GUI::BlobDraw::SP * 3 + alpha }
    end
    def to_blob(); @blob; end
  end
  #---------------------------------------------------------------------------------------------------------
  # How to draw a rectangle with rounded corners.
  class RoundRectangle
    attr_reader :columns, :rows
    def initialize(opt = {})
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
          left_half = "#{GUI::BlobDraw::CP * r}#{GUI::BlobDraw::SP * x_skip}#{GUI::BlobDraw::CP * (x - x_skip - r)}"
        else
          left_half = "#{GUI::BlobDraw::CP * r}#{GUI::BlobDraw::SP * (x - r)}"
        end
        left_half + left_half.reverse
      }.join()
      alpha_channel = top_half + top_half.reverse
      @blob = alpha_channel.gsub(/./) { |alpha| GUI::BlobDraw::SP * 3 + alpha }
    end
    def to_blob(); @blob; end
  end
  #---------------------------------------------------------------------------------------------------------
  # How to draw a circle. When drawing an outline only, it wont do it very well tends to have a flat bottom.
  class Circle
    attr_reader :columns, :rows
    def initialize(opt = {})
      r = opt[:radius]
      @columns = @rows = r * 2
      # start drawing
      lower_half = (0...r).map() { |y|
        x = Math.sqrt(r ** 2 - y ** 2).round()
        if opt[:outline]
          sx = Math.sqrt(r ** 2 - y ** 2).round() - Math.sqrt(opt[:thickness] ** 2).round()
          sx = 0 if sx < 0
          if y >= r - opt[:thickness]
            right_half = "#{GUI::BlobDraw::SP * x}#{GUI::BlobDraw::CP * (r - x)}"
          else
            right_half = "#{GUI::BlobDraw::CP * sx}#{GUI::BlobDraw::SP * (x - sx)}#{GUI::BlobDraw::CP * (r - x)}"
          end
        else
          right_half = "#{GUI::BlobDraw::SP * x}#{GUI::BlobDraw::CP * (r - x)}"
        end
        right_half.reverse + right_half
      }.join()
      alpha_channel = lower_half.reverse + lower_half
      @blob = alpha_channel.gsub(/./) { |alpha| GUI::BlobDraw::SP * 3 + alpha }
    end
    def to_blob(); @blob; end
  end
end
