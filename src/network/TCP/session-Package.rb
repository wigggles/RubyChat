#===============================================================================================================================
# !!!   TCPsession.rb  | Manages a client session and unifies data work between transfers from the server.
#===============================================================================================================================
class TCPsession
  #---------------------------------------------------------------------------------------------------------
  # The expanded more workable type of socket data. Gives the session byte data string workable structure.
  class Package
    attr_reader :ref_id, :data_mode, :data
    attr_reader :created_time, :latency_server, :latency_sender
    CALCULATE_LATENCY = true
    #--------------------------------------
    BYTE_STRING = "q Z10 q n a*"
    ARRAY_LENGTH = 5
    # The above defines how to deal with the string stream of data.
    #
    #    q    | 8-byte integer  | local creation time edian.
    #    Z10  | 10 char bytes   | originating client id.
    #    q    | 8-byte integer  | server touched time edian.
    #    n    | 2-byte signed   | mode integer.
    #    a*   | take whats left | an arbritray length 'message' as a byte string value.
    #--------------------------------------
    BYTE_CLIENTSYNC = "n a*"
    CLIENTSYNC_LENGTH = 2
    BYTE_CLIENT = "Z10 Z20"
    CLIENT_BYTES = 30
    # After using the BYTE_STRING to define common data, perform additonal proccessing.
    #
    #    n    | 2-byte signed   | type integer.
    #    a*   | take whats left | typically a list of clients.
    #
    #    Z10  | 10 char bytes   | refrence ID.
    #    Z20  | 20 char bytes   | client username.
    #--------------------------------------
    BYTE_OBJECT = "Z10 L L n a*"
    OBJECT_LENGTH = 5
    # After using the BYTE_STRING to define common data, perform additonal proccessing.
    #
    #    Z10  | 10 char bytes   | object refrence ID.
    #    L    | 4-byte unsigned | object X world position.
    #    L    | 4-byte unsigned | object Y world position.
    #    n    | 2-byte signed   | type integer.
    #    a*   | take whats left | an arbritray length byte string.
    #--------------------------------------
    BYTE_MAPSYNC = "n a*"
    MAPSYNC_LENGTH = 2
    # After using the BYTE_STRING to define common data, perform additonal proccessing.
    #
    #    n    | 2-byte signed   | type integer.
    #    a*   | take whats left | an arbritray length byte string.
    #--------------------------------------
    # It's crude but effective to count up using constants.
    module DATAMODE
      STRING      = 0    # This mode is the basic one, it just uses the string as a string.
      CLIENT_SYNC = 1    # This mode is when client data is being syncronized.
      OBJECT      = 2    # This mode performs additional variable proccessing for generic data.
      MAP_SYNC    = 3    # This mode is data from the server that is related to a GameWorld.
    end
    #--------------------------------------
    # Knowing the data is half the battle, validate package DATAMODE is being utilized properly.
    def has_valid_data?
      # check the basics first
      return false if @ref_id.nil?
      return false unless (
        @ref_id.length > 0 &&
        @created_time.is_a?(Time) &&
        @data_mode.is_a?(Integer) &&
        !@data.nil?
      )
      # check mode against its defined byte formating for defined package DATAMODE types
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
      Logger.error("TCPSessionData::Package", "Is using an unkown data type. (#{@data_mode.inspect})",
        tags: [:Package]
      )
      return false
    end
    #--------------------------------------
    # Return if there was an error already detected, if not check and return that result.
    def has_error?
      return @error if @error
      @error = !has_valid_data?
      return @error
    end
    #--------------------------------------
    # Create a new Package object to handle byte strings as a class to make interactions more enjoyable.
    def initialize(byte_string = nil, ref_id = nil)
      @ref_id = ref_id || ""
      @arrival_time = nil  # On moment of 'calculate_latency' when package is recieved. 
      @latency_server = 0  # Time it took server to send the packaged message till recieving it.
      @latency_sender = 0  # Time from the originating sender packaging the message till recieving it.
      @error = false
      @extended_mode = 0
      # If a byte string was provided, construct self from that string.
      unpack_byte_string(byte_string) unless byte_string.nil?
    end
    #--------------------------------------
    # Set the package's creation time to current. This is done by the current session socket when the data is sent.
    # '@created_time' is also set when a byte string is unpacked as the package should contain the time stamp.
    def set_creation_time()
      return @created_time = Time.now.utc()
    end
    #--------------------------------------
    # Update client package when the server touches it with a time stamp.
    # This is done during data package forwarding by the server changing this on the client wont have intended effect.
    def set_server_time()
      return @srvr_time_stmp = Time.now.utc()
    end
    #--------------------------------------
    # Calculate ms latency of the packet based off the server. This is done by following 3 time stamps.
    # When a package is created, its stamped locally (client or server). When the server recieves a message,
    # it will 'set_server_time' on the package before sending the data to the active clients. Finally, when
    # the message is recieved by the client, this method 'calculate_latency' is called which sets arival time stamp.
    # The latency of the network packet package and its handeling along the way is calculated in miliseconds.
    def calculate_latency()
      return nil unless Package::CALCULATE_LATENCY
      begin
        @arrival_time = Time.now.utc()
        # server latency is based on how long it took for the message to reach this client from the server.
        # individual client latency is based on how long it took from message creation till arivial as a whole.
        @latency_server = ((@arrival_time - @srvr_time_stmp) * 1000).round()
        @latency_sender = ((@arrival_time - @srvr_time_stmp) * 1000).round()
        # print additional information about session status
        Logger.info("TCPSessionData::Package", 
          "Package latency (Client: #{@latency_sender}ms, Server: #{@latency_server}ms)"+
          "\nClient: #{@created_time.strftime('%H:%M:%S.%L')}"+
          "\nServer: #{@srvr_time_stmp.strftime('%H:%M:%S.%L')}"+
          "\nNow: #{@arrival_time.strftime('%H:%M:%S.%L')}",
          tags: [:Package]  
        )
      rescue => error
        Logger.error("TCPSessionData::Package", "Failed to calculate package latency.",
          tags: [:Package]
        )
        return nil
      end
      return [@latency_sender, @latency_server]
    end
    #--------------------------------------
    # If package is in @data_mode DATAMODE::CLIENT_SYNC bring order to the Array in @data.
    def expand_client_data()
      return nil if @data_mode != DATAMODE::CLIENT_SYNC
      case @data
      when String
        Logger.warn("TCPSessionData::Package", "Client @data in package is still a String.",
          tags: [:Package]
        )
        @extended_mode, unpacked_data = @data.unpack(Package::BYTE_CLIENTSYNC)
        return nil
      when Array
        unless @data.size == Package::CLIENTSYNC_LENGTH
          Logger.error("TCPSessionData::Package", "Client @data in package does not match configured Array size.",
            tags: [:Package]
          )
          return nil
        end
        unpacked_data = @data[1]
        Logger.debug("TCPSessionData::Package", 
          "Recieved DATAMODE::CLIENT_SYNC package. decoding it. Mode: (#{@data[0]})"+
          "\nRaw: (#{@data[1].inspect})"+
          "\nData: (#{unpacked_data.inspect})",
          tags: [:Package]  
        )
      else
        Logger.error("TCPSessionData::Package", "Failed to unpack client @data in it's current state. (#{@data.inspect})",
          tags: [:Package]
        )
        return nil
      end
      # once have the packed string, unpack it into an Array
      unless unpacked_data.is_a?(Array)
        unpacked_data = @data[1].chars.each_slice(Package::CLIENT_BYTES).map(&:join)
        unpacked_data = unpacked_data.map() { |entry|
          ref_id, username = entry.unpack(Package::BYTE_CLIENT)
          [ref_id.delete("\00"), username.delete("\00")]
        }
        @data = [@extended_mode, unpacked_data]
      end
      # {packtype:, client_data:}
      return @data
    end
    #--------------------------------------
    # If package is in @data_mode DATAMODE::OBJECT bring order to the Array in @data.
    def expand_object_data()
      return nil if @data_mode != DATAMODE::OBJECT
      return {
        ref_id:   @data[0],
        world_x:  @data[1],
        world_y:  @data[2],
        type:     @data[3],
        obj_data: @data[4]
      }
    end
    #--------------------------------------
    # If package is in @data_mode DATAMODE::MAP_SYNC bring order to the Array in @data.
    def expand_mapsync_data()
      return nil if @data_mode != DATAMODE::MAP_SYNC
      return {
        packtype: @data[0],
        map_data: @data[1]
      }
    end
    #--------------------------------------
    # Basically all traffic is a single string, packaging bytes in ways you can unpackage in order later.
    # This is not typically called on its own, but used for 'pack_dt' methods.
    def make_byte_string()
      byte_string = [
        @created_time.to_f() * 10000000,
        @ref_id.to_s(),
        @srvr_time_stmp.to_f() * 10000000,
        @data_mode.to_i(),
        @data.to_s()
      ].pack(Package::BYTE_STRING)
      Logger.info("TCPSessionData::Package", "Built new package for DATAMODE:(#{@data_mode})"+
        "\nData: (#{@data.inspect})"+
        "\nPacked: (#{byte_string.inspect})",
        tags: [:Package]
      )
      return byte_string
    end
    #--------------------------------------
    # If data type is for a String, package as such.
    def pack_dt_string(string = nil)
      set_creation_time()
      @data_mode = DATAMODE::STRING
      @data = string unless string.nil?
      return make_byte_string()
    end
    #--------------------------------------
    # If data type is for syncing the client pools between remote/local sessions.
    def pack_dt_client(data_array = nil)
      set_creation_time()
      @data_mode = DATAMODE::CLIENT_SYNC
      if data_array.nil?
        @extended_mode, pool_data = @data
      else
        @extended_mode, pool_data = data_array
      end
      # package client data into an array of byte stings
      unless pool_data.is_a?(String)
        packed_pool = pool_data.map() { |client|
          client.pack(Package::BYTE_CLIENT)
        }.flatten().join()
      end
      Logger.debug("TCPSessionData::Package", "Building client_pool sync package."+
        "\nPool: (#{pool_data.inspect})"+
        "\nPackage: (#{packed_pool})",
        tags: [:Package]
      )
      @data = [@extended_mode, packed_pool].pack(Package::BYTE_CLIENTSYNC)
      # after packaging the data Array, package the entire message for sending over network
      Logger.info("TCPSessionData::Package", "Building sync request for clients."+
        "\nData: (#{data_array.inspect})"+
        "\nPacked: (#{@data.inspect})",
        tags: [:Package]
      )
      return make_byte_string()
    end
    #--------------------------------------
    # If data type is for a generic world/state object.
    def pack_dt_object(data_array = nil)
      set_creation_time()
      @data_mode = DATAMODE::OBJECT
      if data_array.nil?
        ref_id, world_x, world_y, type, obj_data = @data
      else
        ref_id, world_x, world_y, type, obj_data = data_array
      end
      # package the objects data into a byte sting that becomes the string message
      @data = [ref_id, world_x, world_y, type, obj_data].pack(Package::BYTE_OBJECT)
      # after packaging the data Array, package the entire message for sending over network
      return make_byte_string()
    end
    #--------------------------------------
    # If data type is for syncing the map data between client sessions.
    def pack_dt_mapSync(data_array = nil)
      set_creation_time()
      @data_mode = DATAMODE::MAP_SYNC
      if data_array.nil?
        packtype, map_data = @data
      else
        packtype, map_data = data_array
      end
      # package the objects data into a byte sting that becomes the string message
      @data = [packtype, map_data].pack(Package::BYTE_MAPSYNC)
      # after packaging the data Array, package the entire message for sending over network
      return make_byte_string()
    end
    #--------------------------------------
    # Depending on defined mode get the data package byte string. This string is ready to send over socket sessions.
    def get_packed_string(data_mode = nil, for_data = nil)
      @data_mode = data_mode unless data_mode.nil?
      case @data_mode
      when DATAMODE::STRING
        return pack_dt_string() if for_data.nil?
        return pack_dt_string(for_data) if for_data.is_a?(String)
        Logger.error("TCPSessionData::Package", "In STRING mode but did not recieve a String. (#{for_data.inspect})",
          tags: [:Package]
        )
      when DATAMODE::CLIENT_SYNC
        return pack_dt_client() if for_data.nil?
        return pack_dt_client(for_data) if for_data.is_a?(Array)
        Logger.error("TCPSessionData::Package", "In CLIENT_SYNC mode but did not recieve an Array. (#{for_data.inspect})",
          tags: [:Package]
        )
      when DATAMODE::OBJECT
        return pack_dt_object() if for_data.nil?
        return pack_dt_object(for_data) if for_data.is_a?(Array)
        Logger.error("TCPSessionData::Package", "In OBJECT mode but did not recieve an Array. (#{for_data.inspect})",
          tags: [:Package]
        )
      when DATAMODE::MAP_SYNC
        return pack_dt_mapSync() if for_data.nil?
        return pack_dt_mapSync(for_data) if for_data.is_a?(Array)
        Logger.error("TCPSessionData::Package", "In MAP_SYNC mode but did not recieve an Array. (#{for_data.inspect})",
          tags: [:Package]
        )
      else # data mode is not defined
        Logger.warn("TCPSessionData::Package", "In an unkown data mode. #{@data_mode.class}",
          tags: [:Package]
        )
        return nil
      end
    end
    #--------------------------------------
    # Unpack the byte string back into an array of objects.
    def unpack_byte_string(byte_string)
      data_array = byte_string.unpack(Package::BYTE_STRING)
      # validate this new Array has the correct data form
      begin
        ct_time = (data_array[0] / 10000000.0)
        @created_time     = Time.at(ct_time)            # local time message was created
        @ref_id           = data_array[1].delete("\00") # client_id with byte padding removed
        sv_time = (data_array[2] / 10000000.0)
        @srvr_time_stmp   = Time.at(sv_time)            # time when server touched package
        @data_mode        = data_array[3].to_i          # extra data packaging mode defined
        @data             = data_array[4].chomp().to_s  # extra/rest of string byte data recieved
      rescue => error
        Logger.error("TCPSessionData::Package", "Issue during unpacking byte string:"+
          "\nRaw: (#{byte_string.inspect})"+
          "\nData: (#{data_array.inspect})"+
          "\nError: #{error.inspect}\n\n",
          tags: [:Package]  
        )
        @error = true
        return nil
      end
      # perform and additional proccessing to the data byte string if needed
      Logger.info("TCPSessionData::Package", "Unpacking DATAMODE:(#{@data_mode})"+
        "\nRaw (#{byte_string.inspect})"+
        "\nUnpacked Array (#{data_array.inspect})"+
        "\npackage (#{self.inspect})",
        tags: [:Package]
      )
      case @data_mode
      when DATAMODE::STRING
        @data = @data.to_s
      when DATAMODE::CLIENT_SYNC
        @data = @data.unpack(Package::BYTE_CLIENTSYNC)
        unless @data.size == Package::CLIENTSYNC_LENGTH
          Logger.warn("TCPSessionData::Package", "DATAMODE::CLIENT package is malformed. (#{@data.inspect})",
            tags: [:Package]
          )
        end
        @data = expand_client_data()
      when DATAMODE::OBJECT
        @data = @data.unpack(Package::BYTE_OBJECT)
        unless @data.length == Package::OBJECT_LENGTH
          Logger.warn("TCPSessionData::Package", "DATAMODE::OBJECT package is malformed.",
            tags: [:Package]
          )
        end
        @data = expand_object_data()
      when DATAMODE::MAP_SYNC
        @data = @data.unpack(Package::BYTE_MAPSYNC)
        unless @data.length == Package::MAPSYNC_LENGTH
          Logger.warn("TCPSessionData::Package", "DATAMODE::MAP_SYNC package is malformed.",
          tags: [:Package]
        )
        end
        @data = expand_map_data()
      else
        Logger.error("TCPSessionData::Package", "In an unkown DATAMODE (#{@data_mode})",
          tags: [:Package]
        )
        return nil
      end
      Logger.debug("TCPSessionData::Package", "Unpacking DATAMODE:(#{@data_mode})"+
        "\nData: (#{@data.inspect})",
        tags: [:Package]
      )
      return true
    end
    #--------------------------------------
    # Return the byte string message package header and its raw @data as an Array object.
    def to_a()
      return [@created_time, @ref_id, @srvr_time_stmp, @data_mode, @data]
    end
    #--------------------------------------
    # Return the package as a byte string.
    def to_byte_s()
      return get_packed_string()
    end
  end
end
