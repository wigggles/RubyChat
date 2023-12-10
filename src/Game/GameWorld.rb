#===============================================================================================================================
# !!!   GameWorld.rb  |  All Worlds are GameWorld.
#===============================================================================================================================
class GameWorld
  MAX_OBJECTS = 100

  @@parent_state = nil
  #---------------------------------------------------------------------------------------------------------
  def initialize(parent_state)
    @@parent_state = parent_state
    @disposed = false
    @objects = {}
  end
  #---------------------------------------------------------------------------------------------------------
  # To ensure all new id's are unique, use a time based integer.
  def generate_new_ref_id()
    return Time.now().to_i()
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
end
