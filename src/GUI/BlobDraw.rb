#=====================================================================================================================
# !!!  BlobDraw.rb |  Draw extended shapes and cache the pixels into an image blob for drawing later.
#=====================================================================================================================
module GUI::BlobDraw
  SP = 0xff.chr # Solid Pixel
  CP = 0x00.chr # Clear pixel
  # Color is not set here out side of gray scale. The main color is set when the cached blob image is drawn.
  OUTLINE_COLOR = 0xFF_ffffff
  FILL_COLOR    = 0xFF_cccccc
  #---------------------------------------------------------------------------------------------------------
  # Fetch an image that is known how to be drawn.
  def self.get_image(of_type: :circle, width: 50, height: 50, radius: 50, outlined: false, outline: false, thickness: 4)
    #--------------------------------------
    # only works with even blobs, so that gets checked and patched here
    width  += 1 if width.odd?
    height += 1 if height.odd?
    #--------------------------------------
    # after looking at the opt, get the requested blob for drawing
    case of_type
    when :rectangle
      if outline
        Gosu::Image.new(GUI::BlobDraw::Rectangle.new(
                          width, height, outline: true, thickness: thickness
                        ))
      elsif outlined
        outline = Gosu::Image.new(GUI::BlobDraw::Rectangle.new(
                                    width, height, outline: true, thickness: thickness
                                  ))
        width  -= (thickness * 2)
        height -= (thickness * 2)
        fill = Gosu::Image.new(GUI::BlobDraw::Rectangle.new(width, height))
        width  += (thickness * 2)
        height += (thickness * 2)
        image_blob ||= Gosu.render(width, height, retro: true) do
          fill.draw(thickness, thickness, 0, 1.0, 1.0, GUI::BlobDraw::FILL_COLOR)
          outline.draw(0, 0, 0, 1.0, 1.0, GUI::BlobDraw::OUTLINE_COLOR)
        end
        image_blob
      else
        Gosu::Image.new(GUI::BlobDraw::Rectangle.new(width, height))
      end
    #--------------------------------------
    when :round_rect
      if outline
        Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(
                          width, height, radius: radius, outline: true, thickness: thickness
                        ))
      elsif outlined
        outline = Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(
                                    width, height, radius: radius, outline: true, thickness: thickness
                                  ))
        fill = Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(
                                 width - thickness, height - thickness, radius: radius
                               ))
        image_blob ||= Gosu.render(width, height, retro: true) do
          fill.draw(thickness / 2, thickness / 2, 0, 1.0, 1.0, GUI::BlobDraw::FILL_COLOR)
          outline.draw(0, 0, 0, 1.0, 1.0, GUI::BlobDraw::OUTLINE_COLOR)
        end
        image_blob
      else
        Gosu::Image.new(GUI::BlobDraw::RoundRectangle.new(width, height, radius: radius))
      end
    #--------------------------------------
    when :circle
      if outline
        Gosu::Image.new(GUI::BlobDraw::Circle.new(
                          radius, outline: true, thickness: thickness
                        ))
      elsif outlined
        outline = Gosu::Image.new(GUI::BlobDraw::Circle.new(
                                    radius, outline: true, thickness: thickness
                                  ))
        half_rad = (thickness / 2)
        fill = Gosu::Image.new(GUI::BlobDraw::Circle.new(radius - half_rad))
        image_blob ||= Gosu.render(radius * 2, radius * 2, retro: true) do
          fill.draw(half_rad, 0, 0, 1.0, 1.0, GUI::BlobDraw::FILL_COLOR)
          outline.draw(0, 0, 0, 1.0, 1.0, GUI::BlobDraw::OUTLINE_COLOR)
        end
        image_blob
      else
        Gosu::Image.new(GUI::BlobDraw::Circle.new(radius))
      end
    else
      Logger.error('BlobDraw', "Does not know how to draw a (#{of_type})",
                   tags: [:GUI])
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # How to draw a rectangle with square corners.
  class Rectangle
    attr_reader :columns, :rows

    def initialize(width, height, outline: false, thickness: 4)
      @columns = width
      @rows    = height
      # start drawing
      lower_half = (0...(@rows / 2)).map do |y|
        if outline
          x = @columns / 2
          x_skip = (y > thickness ? thickness : x)
          right_half = "#{GUI::BlobDraw::CP * (x - x_skip)}#{GUI::BlobDraw::SP * x_skip}"
        else
          right_half = "#{GUI::BlobDraw::SP * (@columns / 2)}"
        end
        right_half.reverse + right_half
      end.join
      alpha_channel = lower_half + lower_half.reverse
      @blob = alpha_channel.gsub(/./) { |alpha| GUI::BlobDraw::SP * 3 + alpha }
    end

    def to_blob
      @blob
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # How to draw a rectangle with rounded corners.
  class RoundRectangle
    attr_reader :columns, :rows

    def initialize(width, height, radius: 12, outline: false, thickness: 4)
      @columns = width
      @rows    = height
      radius   = [[radius, 2].max, @rows].min
      # start drawing
      top_half = (0...(@rows / 2)).map do |y|
        x = @columns / 2
        r = (y < radius ? radius - Math.sqrt((radius**2) - ((radius - y)**2)).round : 0)
        r = radius - 2 if r >= radius
        if outline
          x_skip = (y > thickness ? thickness : x - r)
          left_half = "#{GUI::BlobDraw::CP * r}#{GUI::BlobDraw::SP * x_skip}#{GUI::BlobDraw::CP * (x - x_skip - r)}"
        else
          left_half = "#{GUI::BlobDraw::CP * r}#{GUI::BlobDraw::SP * (x - r)}"
        end
        left_half + left_half.reverse
      end.join
      alpha_channel = top_half + top_half.reverse
      @blob = alpha_channel.gsub(/./) { |alpha| GUI::BlobDraw::SP * 3 + alpha }
    end

    def to_blob
      @blob
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # How to draw a circle. When drawing an outline only, it wont do it very well tends to have a flat bottom.
  class Circle
    attr_reader :columns, :rows

    def initialize(radius = 50, outline: false, thickness: 4)
      @columns = @rows = radius * 2
      # start drawing
      lower_half = (0...radius).map do |y|
        x = Math.sqrt(radius**2 - y**2).round
        if outline
          sx = Math.sqrt(radius**2 - y**2).round - Math.sqrt(thickness**2).round
          sx = 0 if sx < 0
          right_half = if y >= radius - thickness
                         "#{GUI::BlobDraw::SP * x}#{GUI::BlobDraw::CP * (radius - x)}"
                       else
                         "#{GUI::BlobDraw::CP * sx}#{GUI::BlobDraw::SP * (x - sx)}#{GUI::BlobDraw::CP * (radius - x)}"
                       end
        else
          right_half = "#{GUI::BlobDraw::SP * x}#{GUI::BlobDraw::CP * (radius - x)}"
        end
        right_half.reverse + right_half
      end.join
      alpha_channel = lower_half.reverse + lower_half
      @blob = alpha_channel.gsub(/./) { |alpha| GUI::BlobDraw::SP * 3 + alpha }
    end

    def to_blob
      @blob
    end
  end
end
