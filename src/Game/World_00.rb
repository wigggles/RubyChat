#=====================================================================================================================
# !!!   World_00.rb  |  Generic world where Objects reside in.
#=====================================================================================================================
class World_00 < GameWorld
  #---------------------------------------------------------------------------------------------------------
  def initialize(parent_state, options = {})
    super(parent_state, options)
  end

  #---------------------------------------------------------------------------------------------------------
  def update
    nil unless super()
  end

  #---------------------------------------------------------------------------------------------------------
  def draw
    return unless super()

    if @bgimg.nil?
      @bgimg = GUI::BlobDraw.get_image(
        of_type: :round_rect, width: @view_width, height: @view_height,
        radius: 16, outlined: true, thickness: 12
      )
    end
    @bgimg.draw(@x, @y, 0, 1.0, 1.0, 0xFF_22cc55)
  end

  #---------------------------------------------------------------------------------------------------------
  def dispose
    @bgimg = nil
    super()
  end
end
