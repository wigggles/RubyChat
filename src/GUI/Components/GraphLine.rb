#=====================================================================================================================
# !!!  GraphLine.rb |  Quick way to plot line graph data with in and application.
#-----------------------------------------------------------------------------------------------------------------------
#
#=====================================================================================================================
class GUI::GraphLine < GUI::Component
  attr_reader :drawsize, :disposed

  #---------------------------------------------------------------------------------------------------------
  # Create klass object.
  #---------------------------------------------------------------------------------------------------------
  def initialize(scale: 2, maxPoints: 60, label: nil, **supers)
    super(supers)
    @disposed = false
    @font = Gosu::Font.new(18)
    @scale = scale                      # Scale to use when drawing the graph.
    @maxPoints = maxPoints              # Max number of data points to hold onto, also sets width of graph when drawn.
    @label = label                      # label the graph with a header text display.
    @drawsize = @maxPoints * @scale     # The draw size is rectangular, so width and height both share.
    @graph_data = []                    # Used to plot data to a graph.
    @graph_last = 0                     # last plot that was removed from the graph.
    @graph_peekY = 0                    # Highest Y value to plot.
    @graph_lowY  = 0                    # Lowest Y value to plot.
    @scale_steps = 10                   # number of divisions to draw the scale lines.
    @scale_image = render_graph_scale   # Pre-cached scale margin text.
  end

  #---------------------------------------------------------------------------------------------------------
  # Puts a numeric_value into the graphing data. This data cycles by a max length keeping it contained.
  #---------------------------------------------------------------------------------------------------------
  def plot(numeric_value)
    @graph_data << numeric_value
    return unless @graph_data.size >= @maxPoints

    @graph_last = @graph_data.shift
  end

  #---------------------------------------------------------------------------------------------------------
  # Count up by amount added to last value in @graph_data and add to plot.
  def count_up(amount = 1)
    new_value = @graph_last + amount
    if Configuration::LARGEST_SINT > new_value
      plot(new_value)
    else
      plot(Configuration::LARGEST_SINT)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Count down from last value in @graph_data by amount, add to plot.
  def count_down(amount = 1)
    new_value = @graph_last - amount
    if Configuration::SMALLEST_SINT < new_value
      plot(new_value)
    else
      plot(Configuration::SMALLEST_SINT)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # The graph is drawn with its point plotting data. It's height sets scale for plotting points. Width
  # is based on the increment of the time steps, which is typically frames.
  # https://www.rubydoc.info/gems/gosu/Gosu/Image#draw-instance_method
  #---------------------------------------------------------------------------------------------------------
  def draw
    colorBG = Gosu::Color.argb(0xff_aaaaaa)
    colorScales = Gosu::Color.argb(0xff_33aa77)
    colorLine = Gosu::Color.argb(0xff_aa3377)
    # draw_label
    @font.draw_text(@label.to_s, @x, @y - 24, @z, 1, 1, 0xff_ffffff, :default) unless @label.nil?
    # draw BG
    Gosu.draw_rect(@x, @y, @drawsize, @drawsize, colorBG, Configuration::LARGEST_UINT - 5, :default)
    # draw scale
    @scale_steps.times do |scale_line|
      sy = @y + @drawsize - (@drawsize / @scale_steps * scale_line)
      Gosu.draw_line(@x, sy, colorScales, @x + @drawsize, sy, colorScales, Configuration::LARGEST_UINT - 5, :default)
    end
    # draw plot lines
    px = 0
    last_py = @graph_last
    @graph_data.each do |plot|
      Gosu.draw_line(
        @x + px, @y + @drawsize - last_py, colorLine,
        @x + px + 2, @y + @drawsize - plot, colorLine,
        @z + 1, :default
      )
      last_py = plot
      px += 2
    end
    @scale_image.draw(@x - 14, @y, Configuration::LARGEST_UINT - 5, 1, 1, 0xff_ffffff, :default) if @scale_image
  end

  #---------------------------------------------------------------------------------------------------------
  # Returns the average of all the current data plots stored in the graph_data.
  #---------------------------------------------------------------------------------------------------------
  def mean
    (@graph_data.sum / @graph_data.size).round(2)
  end

  #---------------------------------------------------------------------------------------------------------
  # Since drawing text takes time, here the text used in the scale for a graph is rendered into a cache.
  # https://www.rubydoc.info/gems/gosu/Gosu#render-class_method
  #---------------------------------------------------------------------------------------------------------
  def render_graph_scale
    image ||= Gosu.render(@drawsize / 2, @drawsize, retro: true) do
      @scale_steps.times do |scale_line|
        sy = @drawsize - (@drawsize / @scale_steps * scale_line)
        @font.draw_text(scale_line.to_s, 0, sy - 14, 0, 1, 1, 0xff_ffffff, :default)
      end
    end
    image
  end

  #---------------------------------------------------------------------------------------------------------
  #
  def dispose
    @disposed = true
  end
end
