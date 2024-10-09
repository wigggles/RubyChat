#=====================================================================================================================
# !!!   TCPsession.rb  | Manages a client session and unifies data work between transfers from the server.
#=====================================================================================================================
class TCPsession
  #---------------------------------------------------------------------------------------------------------
  # The expanded more workable type of socket data. Gives the session byte data string workable structure.
  # The length constant accompanying the byte string used when packing/unpacking should match the parts
  # with in it. To assist with this, spaces can and are being used to show package sections for the bytes
  # contained in the string based on their defined string pack flags.
  class Package
    attr_reader :ref_id, :data_mode, :data, :created_time, :latency_server, :latency_sender

    CALCULATE_LATENCY = true

    # WorldObject REF ID size is heavily dependent on the configuration for the string packaging in a server message.
    OBJ_ID_SIZE = 8 # Should match the generated ref_id length. (8 for 'clamped' which is currently configured.)

    # Client REF ID size is heavily dependent on the configuration for the string packaging in a server message.
    CLIENT_ID_SIZE = 10 # Should match the generated ref_id length. (10 for 'unclamped' which is currently configured.)

    #---------------------------------------------------------------------------------------------------------
    BYTE_STRING = "q Z#{TCPsession::Package::CLIENT_ID_SIZE} q n a*"
    ARRAY_LENGTH = 5
    # The above defines how to deal with the string stream of data.
    #
    #    q    | 8-byte integer  | local creation time endian.
    #    Z00  | +0 char bytes   | originating client id. TCPsession::Package::CLIENT_ID_SIZE
    #    q    | 8-byte integer  | server touched time endian.
    #    n    | 2-byte signed   | mode integer.
    #    a*   | take whats left | an arbitrary length 'message' as a byte string value.

    #---------------------------------------------------------------------------------------------------------
    BYTE_CLIENTSYNC = 'n a*'
    CLIENTSYNC_LENGTH = 2
    # The above client sync package can contain multiple client updates with in it, these
    # packages are individualized for each client and can be handled in their own way.
    # Currently, this client package only syncs name changes with in the pool, but can be
    # used to update their location/animation in a game world, or even health and state/status.
    BYTE_CLIENT = "Z#{TCPsession::Package::CLIENT_ID_SIZE} Z20"
    CLIENT_BYTES = 30 # expected size of a client with in a pool sync package. This includes
    # the clients reference ID and a buffered data chunk for pre-defined bytes.
    # After using the BYTE_STRING to define common data, additional processing can be performed.
    #
    #    n    | 2-byte signed   | type integer.
    #    a*   | take whats left | typically a list of clients, bellow is how the list is broken down.
    #
    #    Z00  | +0 char bytes   | reference ID, the TCPsession::Package::CLIENT_ID_SIZE
    #    Z20  | 20 char bytes   | client username.

    #---------------------------------------------------------------------------------------------------------
    BYTE_OBJECT = "Z#{TCPsession::Package::OBJ_ID_SIZE} L L n a*"
    OBJECT_LENGTH = 5
    # The above is for syncing a game object with in a world. This can be a create, door,
    # platform, and/or weapon actions.
    # After using the BYTE_STRING to define common data, perform additional processing.
    #
    #    Z00  | +0 char bytes   | object reference ID, the TCPsession::Package::OBJ_ID_SIZE
    #    L    | 4-byte unsigned | object X world position.
    #    L    | 4-byte unsigned | object Y world position.
    #    n    | 2-byte signed   | type integer.
    #    a*   | take whats left | an arbitrary length byte string.

    #---------------------------------------------------------------------------------------------------------
    BYTE_MAPSYNC = 'n a*'
    MAPSYNC_LENGTH = 2
    # After using the BYTE_STRING to define common data, perform additional processing.
    #
    #    n    | 2-byte signed   | type integer.
    #    a*   | take whats left | an arbitrary length byte string.

    #---------------------------------------------------------------------------------------------------------
    # It's crude but effective to count up using constants.
    module DATAMODE
      STRING      = 0    # This mode is the basic one, it just uses the string as a string.
      CLIENT_SYNC = 1    # This mode is when client data is being synchronize.
      OBJECT      = 2    # This mode performs additional variable processing for generic data.
      MAP_SYNC    = 3    # This mode is data from the server that is related to a GameWorld.
    end

    #---------------------------------------------------------------------------------------------------------
    # Knowing the data is half the battle, validate package DATAMODE is being utilized properly.
    def has_valid_data?
      # check the basics first
      return false if @ref_id.nil?
      return false unless
        @ref_id.length > 0 &&
        @created_time.is_a?(Time) &&
        @data_mode.is_a?(Integer) &&
        !@data.nil?


      # check mode against its defined byte formatting for defined package DATAMODE types
      case @data_mode
      when DATAMODE::STRING
        return @data.is_a?(String)
      when DATAMODE::CLIENT_SYNC
        return false unless @data.is_a?(Array)
        return false unless @data.length == Package::CLIENTSYNC_LENGTH

        return true
      when DATAMODE::OBJECT
        return false unless @data.is_a?(Array)
        return false unless @data.length == Package::OBJECT_LENGTH

        return true
      when DATAMODE::MAP_SYNC
        return false unless @data.is_a?(Array)
        return false unless @data.length == Package::MAPSYNC_LENGTH

        return true
      end
      # @data_mode is of an unknown type
      Logger.error('TCPSessionData::Package', "Is using an Unknown data type. (#{@data_mode.inspect})",
                   tags: [:Package])
      false
    end

    #---------------------------------------------------------------------------------------------------------
    # Return if there was an error already detected, if not check and return that result.
    def has_error?
      return @error if @error

      @error = !has_valid_data?
      @error
    end

    #---------------------------------------------------------------------------------------------------------
    # Create a new Package object to handle byte strings as a class to make interactions more enjoyable.
    def initialize(byte_string = nil, ref_id = nil)
      @ref_id = ref_id || ''
      @arrival_time = nil  # On moment of 'calculate_latency' when package is received.
      @latency_server = 0  # Time it took server to send the packaged message till receiving it.
      @latency_sender = 0  # Time from the originating sender packaging the message till receiving it.
      @error = false
      @extended_mode = 0
      # If a byte string was provided, construct self from that string.
      unpack_byte_string(byte_string) unless byte_string.nil?
    end

    #---------------------------------------------------------------------------------------------------------
    # Set the package's creation time to current. This is done by the current session socket when the data is sent.
    # '@created_time' is also set when a byte string is unpacked as the package should contain the time stamp.
    def set_creation_time
      @created_time = Time.now.utc
    end

    #---------------------------------------------------------------------------------------------------------
    # Update client package when the server touches it with a time stamp.
    # This is done during data package forwarding by the server changing this on the client wont have intended effect.
    def set_server_time
      @srvr_time_stmp = Time.now.utc
    end

    #---------------------------------------------------------------------------------------------------------
    # Calculate ms latency of the packet based off the server. This is done by following 3 time stamps.
    # When a package is created, its stamped locally (client or server). When the server receives a message,
    # it will 'set_server_time' on the package before sending the data to the active clients. Finally, when
    # the message is received by the client, this method 'calculate_latency' is called which sets arrival time stamp.
    # The latency of the network packet package and its handling along the way is calculated in milliseconds.
    def calculate_latency
      return nil unless Package::CALCULATE_LATENCY

      begin
        @arrival_time = Time.now.utc
        # server latency is based on how long it took for the message to reach this client from the server.
        # individual client latency is based on how long it took from message creation till arrival as a whole.
        @latency_server = ((@arrival_time - @srvr_time_stmp) * 1000).round
        @latency_sender = ((@arrival_time - @srvr_time_stmp) * 1000).round
        # print additional information about session status
        Logger.info('TCPSessionData::Package',
                    "Package latency (Client: #{@latency_sender}ms, Server: #{@latency_server}ms)" +
                    "\nClient: #{@created_time.strftime('%H:%M:%S.%L')}" +
                    "\nServer: #{@srvr_time_stmp.strftime('%H:%M:%S.%L')}" +
                    "\nNow: #{@arrival_time.strftime('%H:%M:%S.%L')}",
                    tags: [:Package])
      rescue StandardError
        Logger.error('TCPSessionData::Package', 'Failed to calculate package latency.',
                     tags: [:Package])
        return nil
      end
      [@latency_sender, @latency_server]
    end

    #---------------------------------------------------------------------------------------------------------
    # If package is in @data_mode DATAMODE::CLIENT_SYNC bring order to the Array in @data.
    def expand_client_data
      return nil if @data_mode != DATAMODE::CLIENT_SYNC

      case @data
      when String
        Logger.warn('TCPSessionData::Package', 'Client @data in package is still a String.',
                    tags: [:Package])
        @extended_mode, unpacked_data = @data.unpack(Package::BYTE_CLIENTSYNC)
        return nil
      when Array
        unless @data.size == Package::CLIENTSYNC_LENGTH
          Logger.error('TCPSessionData::Package', 'Client @data in package does not match configured Array size.',
                       tags: [:Package])
          return nil
        end
        unpacked_data = @data[1]
        Logger.debug('TCPSessionData::Package',
                     "received DATAMODE::CLIENT_SYNC package. decoding it. Mode: (#{@data[0]})" +
                     "\nRaw: (#{@data[1].inspect})" +
                     "\nData: (#{unpacked_data.inspect})",
                     tags: [:Package])
      else
        Logger.error('TCPSessionData::Package',
                     "Failed to unpack client @data in it's current state. (#{@data.inspect})",
                     tags: [:Package])
        return nil
      end
      # once have the packed string, unpack it into an Array
      unless unpacked_data.is_a?(Array)
        unpacked_data = @data[1].chars.each_slice(Package::CLIENT_BYTES).map(&:join)
        unpacked_data = unpacked_data.map do |entry|
          ref_id, username = entry.unpack(Package::BYTE_CLIENT)
          [ref_id.delete("\00"), username.delete("\00")]
        end
        @data = [@extended_mode, unpacked_data]
      end
      # {packtype:, client_data:}
      @data
    end

    #---------------------------------------------------------------------------------------------------------
    # If package is in @data_mode DATAMODE::OBJECT bring order to the Array in @data.
    def expand_object_data
      return nil if @data_mode != DATAMODE::OBJECT

      {
        ref_id: @data[0],
        world_x: @data[1],
        world_y: @data[2],
        type: @data[3],
        obj_data: @data[4]
      }
    end

    #---------------------------------------------------------------------------------------------------------
    # If package is in @data_mode DATAMODE::MAP_SYNC bring order to the Array in @data.
    def expand_mapsync_data
      return nil if @data_mode != DATAMODE::MAP_SYNC

      {
        packtype: @data[0],
        map_data: @data[1]
      }
    end

    #---------------------------------------------------------------------------------------------------------
    # Basically all traffic is a single string, packaging bytes in ways you can un-packaged in
    # order later. This is not typically called on its own, but used for 'pack_dt' methods.
    def make_byte_string
      byte_string = [
        @created_time.to_f * 10_000_000,
        @ref_id.to_s,
        @srvr_time_stmp.to_f * 10_000_000,
        @data_mode.to_i,
        @data.to_s
      ].pack(Package::BYTE_STRING)
      Logger.info('TCPSessionData::Package', "Built new package for DATAMODE:(#{@data_mode})" +
        "\nData: (#{@data.inspect})" +
        "\nPacked: (#{byte_string.inspect})",
                  tags: [:Package])
      byte_string
    end

    #---------------------------------------------------------------------------------------------------------
    # If data type is for a String, package as such.
    def pack_dt_string(string = nil)
      set_creation_time
      @data_mode = DATAMODE::STRING
      @data = string unless string.nil?
      make_byte_string
    end

    #---------------------------------------------------------------------------------------------------------
    # If data type is for syncing the client pools between remote/local sessions.
    def pack_dt_client(data_array = nil)
      set_creation_time
      @data_mode = DATAMODE::CLIENT_SYNC
      if data_array.nil?
        @extended_mode, pool_data = @data
      else
        @extended_mode, pool_data = data_array
      end
      # package client data into an array of byte stings
      unless pool_data.is_a?(String)
        packed_pool = pool_data.map do |client|
          client.pack(Package::BYTE_CLIENT)
        end.flatten.join
      end
      Logger.debug('TCPSessionData::Package', 'Building client_pool sync package.' +
        "\nPool: (#{pool_data.inspect})" +
        "\nPackage: (#{packed_pool})",
                   tags: [:Package])
      @data = [@extended_mode, packed_pool].pack(Package::BYTE_CLIENTSYNC)
      # after packaging the data Array, package the entire message for sending over network
      Logger.info('TCPSessionData::Package', 'Building sync request for clients.' +
        "\nData: (#{data_array.inspect})" +
        "\nPacked: (#{@data.inspect})",
                  tags: [:Package])
      make_byte_string
    end

    #---------------------------------------------------------------------------------------------------------
    # If data type is for a generic world/state object.
    def pack_dt_object(data_array = nil)
      set_creation_time
      @data_mode = DATAMODE::OBJECT
      if data_array.nil?
        ref_id, world_x, world_y, type, obj_data = @data
      else
        ref_id, world_x, world_y, type, obj_data = data_array
      end
      # package the objects data into a byte sting that becomes the string message
      @data = [ref_id, world_x, world_y, type, obj_data].pack(Package::BYTE_OBJECT)
      # after packaging the data Array, package the entire message for sending over network
      make_byte_string
    end

    #---------------------------------------------------------------------------------------------------------
    # If data type is for syncing the map data between client sessions.
    def pack_dt_mapSync(data_array = nil)
      set_creation_time
      @data_mode = DATAMODE::MAP_SYNC
      if data_array.nil?
        packtype, map_data = @data
      else
        packtype, map_data = data_array
      end
      # package the objects data into a byte sting that becomes the string message
      @data = [packtype, map_data].pack(Package::BYTE_MAPSYNC)
      # after packaging the data Array, package the entire message for sending over network
      make_byte_string
    end

    #---------------------------------------------------------------------------------------------------------
    # Depending on defined mode get the data package byte string. This string is ready to send over socket sessions.
    def get_packed_string(data_mode = nil, for_data = nil)
      @data_mode = data_mode unless data_mode.nil?
      case @data_mode
      when DATAMODE::STRING
        return pack_dt_string if for_data.nil?
        return pack_dt_string(for_data) if for_data.is_a?(String)

        Logger.error('TCPSessionData::Package', "In STRING mode but did not receive a String. (#{for_data.inspect})",
                     tags: [:Package])
      when DATAMODE::CLIENT_SYNC
        return pack_dt_client if for_data.nil?
        return pack_dt_client(for_data) if for_data.is_a?(Array)

        Logger.error('TCPSessionData::Package',
                     "In CLIENT_SYNC mode but did not receive an Array. (#{for_data.inspect})",
                     tags: [:Package])
      when DATAMODE::OBJECT
        return pack_dt_object if for_data.nil?
        return pack_dt_object(for_data) if for_data.is_a?(Array)

        Logger.error('TCPSessionData::Package', "In OBJECT mode but did not receive an Array. (#{for_data.inspect})",
                     tags: [:Package])
      when DATAMODE::MAP_SYNC
        return pack_dt_mapSync if for_data.nil?
        return pack_dt_mapSync(for_data) if for_data.is_a?(Array)

        Logger.error('TCPSessionData::Package', "In MAP_SYNC mode but did not receive an Array. (#{for_data.inspect})",
                     tags: [:Package])
      else # data mode is not defined
        Logger.warn('TCPSessionData::Package', "In an Unknown data mode. #{@data_mode.class}",
                    tags: [:Package])
        nil
      end
    end

    #---------------------------------------------------------------------------------------------------------
    # Unpack the byte string back into an array of objects.
    def unpack_byte_string(byte_string)
      data_array = byte_string.unpack(Package::BYTE_STRING)
      # validate this new Array has the correct data form
      begin
        ct_time = (data_array[0] / 10_000_000.0)
        @created_time     = Time.at(ct_time)            # local time message was created
        @ref_id           = data_array[1].delete("\00") # client_id with byte padding removed
        sv_time = (data_array[2] / 10_000_000.0)
        @srvr_time_stmp   = Time.at(sv_time)            # time when server touched package
        @data_mode        = data_array[3].to_i          # extra data packaging mode defined
        @data             = data_array[4].chomp.to_s # extra/rest of string byte data received
      rescue StandardError => e
        Logger.error('TCPSessionData::Package', 'Issue during unpacking byte string:' +
          "\nRaw: (#{byte_string.inspect})" +
          "\nData: (#{data_array.inspect})" +
          "\nError: #{e.inspect}\n\n",
                     tags: [:Package])
        @error = true
        return nil
      end
      # perform and additional processing to the data byte string if needed
      Logger.info('TCPSessionData::Package', "Unpacking DATAMODE:(#{@data_mode})" +
        "\nRaw (#{byte_string.inspect})" +
        "\nUnpacked Array (#{data_array.inspect})" +
        "\npackage (#{inspect})",
                  tags: [:Package])
      case @data_mode
      when DATAMODE::STRING
        @data = @data.to_s
      when DATAMODE::CLIENT_SYNC
        @data = @data.unpack(Package::BYTE_CLIENTSYNC)
        unless @data.size == Package::CLIENTSYNC_LENGTH
          Logger.warn('TCPSessionData::Package', "DATAMODE::CLIENT package is malformed. (#{@data.inspect})",
                      tags: [:Package])
        end
        @data = expand_client_data
      when DATAMODE::OBJECT
        @data = @data.unpack(Package::BYTE_OBJECT)
        unless @data.length == Package::OBJECT_LENGTH
          Logger.warn('TCPSessionData::Package', 'DATAMODE::OBJECT package is malformed.',
                      tags: [:Package])
        end
        @data = expand_object_data
      when DATAMODE::MAP_SYNC
        @data = @data.unpack(Package::BYTE_MAPSYNC)
        unless @data.length == Package::MAPSYNC_LENGTH
          Logger.warn('TCPSessionData::Package', 'DATAMODE::MAP_SYNC package is malformed.',
                      tags: [:Package])
        end
        @data = expand_map_data
      else
        Logger.error('TCPSessionData::Package', "In an Unknown DATAMODE (#{@data_mode})",
                     tags: [:Package])
        return nil
      end
      Logger.debug('TCPSessionData::Package', "Unpacking DATAMODE:(#{@data_mode})" +
        "\nData: (#{@data.inspect})",
                   tags: [:Package])
      true
    end

    #---------------------------------------------------------------------------------------------------------
    # Return the byte string message package header and its raw @data as an Array object.
    def to_a
      [@created_time, @ref_id, @srvr_time_stmp, @data_mode, @data]
    end

    #---------------------------------------------------------------------------------------------------------
    # Return the package as a byte string.
    def to_byte_s
      get_packed_string
    end
  end
end
