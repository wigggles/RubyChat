  
#===============================================================================================================================
# !!!  GraphLine.rb |  Quick way to plot line graph data with in and application.
#-------------------------------------------------------------------------------------------------------------------------------
#
#===============================================================================================================================
class GraphLine
  attr_reader :drawsize, :disposed
  @@font = Gosu::Font.new(18)
  #---------------------------------------------------------------------------------------------------------
  #D: Create klass object.
  #---------------------------------------------------------------------------------------------------------
  def initialize(options = {})
    @disposed = false
    @scale = options[:scale] || 2          # Scale to use when drawing the graph.
    @maxPoints = options[:maxPoints] || 60 # Max number of data points to hold onto, also sets width of graph when drawn.
    @label = options[:label] || nil # Lable the graph with a header text display.
    @drawsize = @maxPoints * @scale # The draw size is rectangular, so width and height both share.
    @graph_data = []   # Used to plot data to a graph.
    @graph_last = 0    # last plot that was removed from the graph.
    @graph_peekY = 0   # Highest Y value to plot.
    @graph_lowY  = 0   # Lowest Y value to plot.
    @scale_steps = 10  # number of divisions to draw the scale lines.
    @scale_image = render_graph_scale() # Pre-cached scale margin text.
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Puts a numeric_value into the graphing data. This data cycles by a max length keeping it contained.
  #---------------------------------------------------------------------------------------------------------
  def plot(numeric_value)
    @graph_data << numeric_value
    if @graph_data.size >= @maxPoints
      @graph_last = @graph_data.shift()
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Count up by amount added to last value in @graph_data and add to plot.
  def count_up(amount = 1)
    new_value = @graph_last + amount
    if Configuration::LARGEST_SINT > new_value
      plot(new_value)
    else
      plot(Configuration::LARGEST_SINT)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Count down from last value in @graph_data by amount, add to plot.
  def count_down(amount = 1)
    new_value = @graph_last - amount
    if Configuration::SMALLEST_SINT < new_value
      plot(new_value)
    else
      plot(Configuration::SMALLEST_SINT)
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
    @scale_steps.times do |scale_line|
      sy = y + @drawsize - (@drawsize / @scale_steps * scale_line)
      Gosu.draw_line(x, sy, colorScales, x + @drawsize, sy, colorScales, Configuration::LARGEST_UINT - 5, :default)
    end
    # draw plot lines
    px = 0
    last_py = @graph_last
    @graph_data.each do |plot|
      Gosu.draw_line(
        x + px, y + @drawsize - last_py, colorLine,
        x + px + 2, y + @drawsize - plot, colorLine,
        Configuration::LARGEST_UINT - 1, :default
      )
      last_py = plot
      px += 2
    end
    @scale_image.draw(x - 14, y, Configuration::LARGEST_UINT - 5, 1, 1, 0xff_ffffff, :default) if @scale_image
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Returns the average of all the current data plots stored in the graph_data.
  #---------------------------------------------------------------------------------------------------------
  def mean()
    return (@graph_data.sum() / @graph_data.size).round(2)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Since drawing text takes time, here the text used in the scale for a graph is rendered into a cache.
  # https://www.rubydoc.info/gems/gosu/Gosu#render-class_method
  #---------------------------------------------------------------------------------------------------------
  def render_graph_scale()
    image ||= Gosu.render(@drawsize / 2, @drawsize, retro: true) do 
      @scale_steps.times do |scale_line|
        sy = @drawsize - (@drawsize / @scale_steps * scale_line)
        @@font.draw_text(scale_line.to_s, 0, sy - 14, 0, 1, 1, 0xff_ffffff, :default)
      end
    end
    return image
  end
  #---------------------------------------------------------------------------------------------------------
  #D: 
  def dispose()
    @disposed = true
  end
#===============================================================================================================================
end

#===============================================================================================================================
# This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either Version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free 
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#===============================================================================================================================
