  
#===============================================================================================================================
# !!!  GraphBar.rb |  Quick way to plot bar graph data with in and application.
#-------------------------------------------------------------------------------------------------------------------------------
#
#===============================================================================================================================
class GraphBar
  attr_reader :drawsize, :disposed
  @@font = Gosu::Font.new(18)
  #---------------------------------------------------------------------------------------------------------
  #D: Create klass object.
  #---------------------------------------------------------------------------------------------------------
  def initialize(options = {})
    @disposed = false
    @graph_data = options[:init_data] || {} # Used to plot data to a graph.
    @label = options[:label] || nil # label the graph with a header text display.
    @graph_peekY = 0   # Highest Y value to plot.
    @graph_lowY  = 0   # Lowest Y value to plot.
    @value_steps = 8  # number of divisions to draw the value lines.
    @scale = 2      # Scale to use when drawing the graph.
    # The draw size is rectangular, so width and height both share.
    @drawsize = @graph_data.keys.size() * @value_steps * @scale
    @key_image = render_graph_key() # Pre-cached bar key text.
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Puts a numeric_value into the graphing data.
  #---------------------------------------------------------------------------------------------------------
  def plot(key, numeric_value = 0)
    @graph_data[key] = numeric_value
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Count up by amount added to last value in @graph_data and add to plot.
  def count_up(key, amount = 1)
    if @graph_data[key].nil?
      Logger.warn("GraphBar", "Can't count_up, key doesn't exist. [#{key}]")
      return
    end
    new_value = @graph_data[key] + amount
    if Configuration::LARGEST_SINT > new_value
      plot(key, new_value)
    else
      plot(key, Configuration::LARGEST_SINT)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Count down from last value in @graph_data by amount, add to plot.
  def count_down(key, amount = 1)
    if @graph_data[key].nil?
      Logger.warn("GraphBar", "Can't count_down, key doesn't exist. [#{key}]")
      return
    end
    new_value = @graph_data[key] - amount
    if Configuration::SMALLEST_SINT < new_value
      plot(key, new_value)
    else
      plot(key, Configuration::SMALLEST_SINT)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: The graph is drawn with its point plotting data. It's height sets scale for plotting points. Width
  #D: is based on the increment of the time steps, which is typically frames.
  # https://www.rubydoc.info/gems/gosu/Gosu/Image#draw-instance_method
  #---------------------------------------------------------------------------------------------------------
  def draw(x=0, y=0)
    colorBG = Gosu::Color.argb(0xff_aaaaaa)
    colorScales = Gosu::Color.argb(0xff_33aa77)
    colorLine = Gosu::Color.argb(0xff_aa3377)
    # draw_label
    @@font.draw_text(@label.to_s, x, y - 24, 0, 1, 1, 0xff_ffffff, :default) unless @label.nil?
    # draw BG
    Gosu.draw_rect(x, y, @drawsize, @drawsize, colorBG, Configuration::LARGEST_UINT - 5, :default)
    # draw scale
    @value_steps.times do |scale_line|
      sy = y + @drawsize - (@drawsize / @value_steps * scale_line)
      Gosu.draw_line(x, sy, colorScales, x + @drawsize, sy, colorScales, Configuration::LARGEST_UINT - 5, :default)
    end
    # draw plot lines
    px = 0
    @graph_data.keys.reverse.each do |key|
      value = @graph_data[key]
      @graph_peekY = value if @graph_peekY < value
      fill = @drawsize * (value.to_f / @graph_peekY.to_f)
      Gosu.draw_rect(x + px, y - fill + @drawsize, 7 * @scale, fill, colorLine, Configuration::LARGEST_UINT, :default)
      px += 8 * @scale
    end
    @key_image.draw(x, y + @drawsize + 6, Configuration::LARGEST_UINT - 5, 1, 1, 0xff_ffffff, :default) if @key_image
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Since drawing text takes time, so text used in the key display for a graph is rendered into a cache.
  # https://www.rubydoc.info/gems/gosu/Gosu#render-class_method
  #---------------------------------------------------------------------------------------------------------
  def render_graph_key()
    image ||= Gosu.render(@drawsize, @drawsize, retro: true) do
      sy = 0
      Gosu.rotate(90, @drawsize / 2, @drawsize / 2) {
        @graph_data.each do |key, value|
          @@font.draw_text(key.to_s, 0, sy, 0, 1, 1, 0xff_ffffff, :default)
          sy += 16
        end
      }
    end
    return image
  end
  #---------------------------------------------------------------------------------------------------------
  #D: 
  def dispose()
    @disposed = true
  end
end
