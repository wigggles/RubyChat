#=====================================================================================================================
# !!!   GameWorld.rb  |  All Worlds are GameWorld.
#=====================================================================================================================
class GameWorld
  MAX_OBJECTS = 100

  attr_accessor :x, :y, :world_x, :world_y, :view_width, :view_height
  attr_reader :width, :height, :objects

  #---------------------------------------------------------------------------------------------------------
  def initialize(parent_state, options = {})
    @parent_state = parent_state
    @disposed = false
    # Where the world is drawn at with in the GUI window
    @x ||= options[:pos_x] || 0
    @y ||= options[:pos_y] || 0
    # How much of the GameWorld is shown with in the GUI window
    unless $application.nil?
      @view_width ||= options[:view_width] || $application.width / 4
      @view_height ||= options[:view_height] || $application.height / 4
    end
    # Used for offsetting the draws for tilemaps/WorldObjects
    @world_x ||= options[:world_x] || 0
    @world_y ||= options[:world_y] || 0
    # The lookup sizes for the map's terrain/tilemap data
    @width ||= options[:width] || 0
    @height ||= options[:height] || 0
    # Objects with in the world
    @objects ||= {}
  end

  #---------------------------------------------------------------------------------------------------------
  # Create a new WorldObject and add it into the update and draw loops.
  def create_object(options = {})
    if @objects.keys.size >= GameWorld::MAX_OBJECTS
      Logger.warn('GameWorld',
                  "(#{self.class}) has reached the maximum number of WorldObjects. (#{GameWorld::MAX_OBJECTS})")
    else
      new_object = WorldObject.new(self, options)
      @objects[new_object.ref_id] = new_object
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Get a WorldObject if it exists in the world.
  def get_object(ref_id)
    return nil if @parent_state.nil? || @disposed

    @objects[ref_id]
  end

  #---------------------------------------------------------------------------------------------------------
  # Remove an object from the world.
  def dispose_object(ref_id)
    return nil if @parent_state.nil? || @disposed

    if @objects[ref_id]
      @objects[ref_id].dispose
      @objects[ref_id].delete
      return true
    end
    nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Server called synchronizing WorldObject with clients.
  def world_object_change(ref_id = 0, options = {})
    return nil if $application.nil? || @disposed

    if $application.is_server?
      new_x = options[:new_x] || options[:move_toX] || 0   # Where the object is at currently, this is sent to
      new_y = options[:new_y] || options[:move_toX] || 0   # inform clients where objects are in the world locally.
      data_package = $application.new_session_package
      data_package.pack_dt_object([ref_id, new_x, new_y])
      $application.send_socket_data(data_package)
      return true
    end
    Logger.warn('GameWorld', 'Only the server can update world objects.')
    nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Synchronizing GameWorld with clients.
  def sync_world
    return nil if $application.nil? || @disposed

    if $application.is_server?
      data_package = $application.new_session_package
      packtype = 0   # How the map_data should be packaged
      map_data = []  # An array of data used to sync a portion of the world
      data_package.pack_dt_object([packtype, map_data])
      $application.send_socket_data(data_package)
      return true
    end
    Logger.warn('GameWorld', 'Only the server can update the world.')
    nil
  end

  #---------------------------------------------------------------------------------------------------------
  # There has been an update to an object, reflect changes to this local client instance.
  def world_object_sync(object_package)
    Logger.debug('GameWorld', "Is syncing an object with a package. (#{object_package.inspect})")
  end

  #---------------------------------------------------------------------------------------------------------
  # There has been an update to the world, reflect changes to this local client instance.
  def world_sync(world_package)
    Logger.debug('GameWorld', "Is syncing the world with a package. (#{world_package.inspect})")
  end

  #---------------------------------------------------------------------------------------------------------
  def update
    return if @parent_state.nil? || @disposed

    @objects.each do |_ref_id, world_object|
      world_object.update
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Draw the WorldObjects known to exist in the world.
  def draw
    return if @parent_state.nil? || @disposed

    @objects.each do |_ref_id, world_object|
      world_object.draw
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def dispose
    @objects.each do |_ref_id, world_object|
      world_object.dispose
    end
    @disposed = true
  end

  #---------------------------------------------------------------------------------------------------------
  def disposed?
    @disposed
  end
end
