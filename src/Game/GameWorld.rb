#===============================================================================================================================
# !!!   GameWorld.rb  |  All Worlds are GameWorld.
#===============================================================================================================================
class GameWorld
  MAX_OBJECTS = 100

  @@parent_state = nil

  attr_accessor :x, :y, :world_x, :world_y, :view_width, :view_height
  attr_reader :width, :height, :objects
  #---------------------------------------------------------------------------------------------------------
  def initialize(parent_state, options = {})
    @@parent_state = parent_state
    @disposed = false
    # Where the world is drawn at with in the GUI window
    @x = options[:x] || 0 unless @x
    @y = options[:y] || 0 unless @y
    # How much of the GameWorld is shown with in the GUI window
    @view_width  = options[:view_width]  || Configuration::SCREEN_WIDTH  / 4 unless @view_width
    @view_height = options[:view_height] || Configuration::SCREEN_HEIGHT / 4 unless @view_height
    # Used for offsetting the draws for tilemaps/WorldObjects
    @world_x = options[:world_x] || 0 unless @world_x
    @world_y = options[:world_y] || 0 unless @world_y
    # The lookup sizes for the map's terrian/tilemap data
    @width  = options[:width]  || 0 unless @width
    @height = options[:height] || 0 unless @height
    # Objects with in the world
    @objects = {} unless @objects
  end
  #---------------------------------------------------------------------------------------------------------
  # Create a new WorldObject and add it into the update and draw loops.
  def create_object(options = {})
    if @objects.keys.size() >= GameWorld::MAX_OBJECTS
      Logger.warn("GameWorld", "(#{self.class}) has reached the maximum number of WorldObjects. (#{GameWorld::MAX_OBJECTS})")
    else
      new_object = WorldObject.new(self, options)
      @objects[new_object.ref_id] = new_object
    end
  end
  #---------------------------------------------------------------------------------------------------------
  # Get a WorldObject if it exists in the world.
  def get_object(ref_id)
    return nil if @@parent_state.nil? || @disposed
    return @objects[ref_id]
  end
  #---------------------------------------------------------------------------------------------------------
  # Remove an object from the world.
  def dispose_object(ref_id)
    return nil if @@parent_state.nil? || @disposed
    if @objects[ref_id]
      @objects[ref_id].dispose()
      @objects[ref_id].delete()
      return true
    end
    return nil
  end
  #---------------------------------------------------------------------------------------------------------
  # Server called syncronizing WorldObject with clients.
  def world_object_change(ref_id = 0, options = {})
    return nil if @@parent_window.nil? || @disposed
    if @@parent_window.is_server?
      new_x = options[:new_x] || options[:move_toX] || 0   # Where the object is at currently, this is sent to
      new_y = options[:new_y] || options[:move_toX] || 0   # inform clients where objects are in the world locally.
      data_package = @@parent_window.getNew_session_package()
      data_package.pack_dt_object([ref_id, new_x, new_y])
      @@parent_window.send_socket_data(data_package)
      return true
    end
    Logger.warn("GameWorld", "Only the server can update world objects.")
    return nil
  end
  #---------------------------------------------------------------------------------------------------------
  # Syncronizing GameWorld with clients.
  def sync_world()
    return nil if @@parent_window.nil? || @disposed
    if @@parent_window.is_server?
      data_package = @@parent_window.getNew_session_package()
      packtype = 0   # How the map_data should be packaged
      map_data = []  # An array of data used to sync a portion of the world
      data_package.pack_dt_object([packtype, map_data])
      @@parent_window.send_socket_data(data_package)
      return true
    end
    Logger.warn("GameWorld", "Only the server can update the world.")
    return nil
  end
  #---------------------------------------------------------------------------------------------------------
  # There has been an update to an object, reflect changes to this local client instance.
  def world_object_sync(object_package)
    Logger.debug("GameWorld", "Is syncing an object with a package. (#{object_package.inspect})")
  end
  #---------------------------------------------------------------------------------------------------------
  # There has been an update to the world, reflect changes to this local client instance.
  def world_sync(world_package)
    Logger.debug("GameWorld", "Is syncing the world with a package. (#{world_package.inspect})")
  end
  #---------------------------------------------------------------------------------------------------------
  def update()
    return if @@parent_state.nil? || @disposed
    @objects.each { |ref_id, world_object|
      world_object.update()
    }
  end
  #---------------------------------------------------------------------------------------------------------
  # Draw the WorldObjects known to exist in the world.
  def draw()
    return if @@parent_state.nil? || @disposed
    @objects.each { |ref_id, world_object|
      world_object.draw()
    }
  end
  #---------------------------------------------------------------------------------------------------------
  def dispose()
    @objects.each { |ref_id, world_object|
      world_object.dispose()
    }
    @disposed = true
  end
  #---------------------------------------------------------------------------------------------------------
  def disposed?
    return @disposed
  end
end
