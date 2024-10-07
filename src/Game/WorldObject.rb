#===============================================================================================================================
# !!!   WorldObject.rb  |  Generic world Object for use with in Worlds.
#===============================================================================================================================
class WorldObject
  attr_reader :ref_id, :type
  attr_accessor :world_x, :world_y
  #---------------------------------------------------------------------------------------------------------
  def initialize(parent_world, options = {})
    @parent_world = parent_world
    @ref_id = Configuration.generate_new_ref_id({as_string: true, clamp: true})
    @world_x = options[:world_x] || 0
    @world_y = options[:world_y] || 0
    @type = options[:type] || 0
    @disposed = false
  end
  #---------------------------------------------------------------------------------------------------------
  def update()
    return if @parent_world.nil? || @disposed
  end
  #---------------------------------------------------------------------------------------------------------
  def draw()
    return if @parent_world.nil? || @disposed
  end
  #---------------------------------------------------------------------------------------------------------
  def dispose()
    @disposed = true
  end
end
