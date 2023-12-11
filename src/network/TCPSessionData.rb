#===============================================================================================================================
# !!!   TCPSessionData.rb  | Manages a client session and unifies data work between transfers from the server.
#===============================================================================================================================
class TCPSessionData
  attr_accessor :username

  @@client_pool = nil
  @@client_self = nil
  #--------------------------------------
  # Option to send raw byte strings instead of inflating by a factor of two and sending a hex string representation.
  # If you can manage to avoid end-line flags when packaging raw data then you can use raw strings. Otherwise its
  # recomended you instead send a string of characters to represent these bytes which later can be turned back into
  # a byte string where ever the network message is recieved. This means instead of a message of 1024 bytes, you 
  # can send a message of 512 bytes for a maximum payload size.
  USE_RAW_STRING_PACKAGE = false  # ** Default is 'false'.
  #--------------------------------------
  FORCE_ENCODING = Encoding::ASCII_8BIT
  # nil
  # Encoding::UTF_8
  # Encoding::ASCII
  # Encoding::ASCII_8BIT

  #---------------------------------------------------------------------------------------------------------
  # The expanded more workable type of socket data. Gives the session byte data string workable structure.
  class Package
    attr_reader :user_id, :data_mode, :data
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
      return false if @user_id.nil?
      return false unless (
        @user_id.length > 0 &&
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
      Logger.error("TCPSessionData::Package", "Is using an unkown data type. (#{@data_mode.inspect})")
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
    def initialize(byte_string = nil, user_id = nil)
      @user_id = user_id || ""
      @arrival_time = nil  # On moment of 'calculate_latency' when package is recieved. 
      @latency_server = 0  # Time it took server to send the packaged message till recieving it.
      @latency_sender = 0  # Time from the originating sender packaging the message till recieving it.
      @error = false
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
          "\nNow: #{@arrival_time.strftime('%H:%M:%S.%L')}"
        )
      rescue => error
        Logger.error("TCPSessionData::Package", "Failed to calculate package latency.")
        return nil
      end
      return [@latency_sender, @latency_server]
    end
    #--------------------------------------
    # If package is in @data_mode DATAMODE::CLIENT_SYNC bring order to the Array in @data.
    def client_data()
      return nil if @data_mode != DATAMODE::CLIENT_SYNC
      unpacked_data = @data[1].chars.each_slice(Package::CLIENT_BYTES).map(&:join)
      unpacked_data = unpacked_data.map() { |entry|
        ref_id, username = entry.unpack(Package::BYTE_CLIENT)
        [ref_id.delete("\00"), username.delete("\00")]
      }
      return {
        packtype: @data[0],
        pool_data: unpacked_data
      }
    end
    #--------------------------------------
    # If package is in @data_mode DATAMODE::OBJECT bring order to the Array in @data.
    def object_data()
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
    def mapsync_data()
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
      return [
        @created_time.to_f() * 10000000,
        @user_id,
        @srvr_time_stmp.to_f() * 10000000,
        @data_mode,
        @data
      ].pack(Package::BYTE_STRING) 
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
        packtype, pool_data = @data
      else
        packtype, pool_data = data_array
      end
      # package client data into an array of byte stings
      unless pool_data.is_a?(String)
        packed_pool = pool_data.map() { |client|
          client.pack(Package::BYTE_CLIENT)
        }
      end
      Logger.info("TCPSessionData", "Sending to clients. (#{pool_data.inspect})")
      @data = [packtype, packed_pool].flatten.pack(Package::BYTE_CLIENTSYNC)
      # after packaging the data Array, package the entire message for sending over network
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
      @data = for_data unless for_data.nil?
      case @data_mode
      when DATAMODE::STRING
        return pack_dt_string() if @data.is_a?(String)
        Logger.error("TCPSessionData::Package", "In STRING mode but did not recieve a String.")
      when DATAMODE::CLIENT_SYNC
        return pack_dt_client() if @data.is_a?(Array)
        Logger.error("TCPSessionData::Package", "In CLIENT_SYNC mode but did not recieve an Array.")
      when DATAMODE::OBJECT
        return pack_dt_object() if @data.is_a?(Array)
        Logger.error("TCPSessionData::Package", "In OBJECT mode but did not recieve an Array.")
      when DATAMODE::MAP_SYNC
        return pack_dt_mapSync() if @data.is_a?(Array)
        Logger.error("TCPSessionData::Package", "In MAP_SYNC mode but did not recieve an Array.")
      else # data mode is not defined
        Logger.warn("TCPSessionData::Package", "In an unkown data mode. #{@data_mode.class}")
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
        @user_id          = data_array[1].delete("\00") # client_id with byte padding removed
        sv_time = (data_array[2] / 10000000.0)
        @srvr_time_stmp   = Time.at(sv_time)            # time from server
        @data_mode        = data_array[3].to_i          # extra data packaging mode
        @data             = data_array[4]               # extra/rest of data bytes sent
      rescue => error
        Logger.error("TCPSessionData::Package", "Issue during unpacking byte string:"+
          "\nRaw: (#{byte_string.inspect})"+
          "\nData: (#{data_array.inspect})"+
          "\nError: #{error.inspect}\n\n"
        )
        @error = true
        return nil
      end
      # perform and additional proccessing to the data byte string if needed
      case @data_mode
      when DATAMODE::STRING
        @data = @data.to_s
      when DATAMODE::CLIENT_SYNC
        @data = @data.unpack(Package::BYTE_CLIENTSYNC)
        unless @data.size == Package::CLIENTSYNC_LENGTH
          Logger.warn("TCPSessionData::Package", "DATAMODE::CLIENT package is malformed. (#{@data.inspect})")
        end
      when DATAMODE::OBJECT
        @data = @data.unpack(Package::BYTE_OBJECT)
        unless @data.length == Package::OBJECT_LENGTH
          Logger.warn("TCPSessionData::Package", "DATAMODE::OBJECT package is malformed.")
        end
      when DATAMODE::MAP_SYNC
        @data = @data.unpack(Package::BYTE_MAPSYNC)
        unless @data.length == Package::MAPSYNC_LENGTH
          Logger.warn("TCPSessionData::Package", "DATAMODE::MAP_SYNC package is malformed.")
        end
      else
        Logger.error("TCPSessionData::Package", "In an unkown DATAMODE (#{@data_mode})")
      end
      Logger.info("TCPSessionData::Package", "Unpacking byte string"+
        "\nRaw (#{byte_string.inspect})"+
        "\nUnpacked Array (#{data_array.inspect})"+
        "\npackage (#{self.inspect})"
      )
      return true
    end
    #--------------------------------------
    # Return the byte string message package header and its raw @data as an Array object.
    def to_a()
      return [@created_time, @user_id, @srvr_time_stmp, @data_mode, @data]
    end
    #--------------------------------------
    # Return the package as a byte string.
    def to_byte_s()
      return get_packed_string()
    end
  end

#===============================================================================================================================
# Create the session and manage the packages of byte data strings sent accross connected sockets.
#===============================================================================================================================
  def initialize(socket, username = "")
    @creation_time = Time.now.utc()
    @socket = socket
    @@client_pool = ClientPool.new(self)
    @@client_self = ClientPool::Client.new(username: username, session_pointer: self)
    request_sync_client()
  end

  #---------------------------------------------------------------------------------------------------------
  # Check if provided user ref_id is the same one as the local session.
  def is_self?(this_user_id = nil)
    return nil if @@client_self.nil?
    return @@client_self.ref_id == this_user_id
  end

  #---------------------------------------------------------------------------------------------------------
  # Get local self's public description shown between clients connected to the same server.
  def description()
    return @@client_self
  end

  #---------------------------------------------------------------------------------------------------------
  # Return all the currently known clients.
  def get_client_pool()
    return @@client_pool
  end

  #---------------------------------------------------------------------------------------------------------
  # Request a change to @@client_self be synced by the server to other client sessions.
  def request_sync_client()
    Logger.info("TCPSessionData", "Local client is requesting a change to its public description. (#{@@client_self.inspect})")
    @@client_pool.sync_client(@@client_self)
  end

  #---------------------------------------------------------------------------------------------------------
  # Return a new Package object to load data into in preperation for sending over network session.
  def empty_data_package()
    return nil if @@client_self.nil?
    return Package.new(nil, @@client_self.ref_id)
  end

  #---------------------------------------------------------------------------------------------------------
  # Package send data array into a byte string depending on kown types.
  def package_data(data_to_send)
    return nil if @@client_self.nil?
    new_data_package = Package.new(nil, @@client_self.ref_id)
    case data_to_send
    when String
      character_count = data_to_send.length()
      if character_count > 128
        Logger.warn("TCPSessionData", "Attempting to send a message that is too long. #{character_count}")
        data_to_send = "'msg too long' #{character_count}"
      end
      byte_string_package = new_data_package.get_packed_string(Package::DATAMODE::STRING, data_to_send)
    else
      Logger.error("TCPSessionData", "Does not know how to send data of class type: #{data_to_send.class}")
      return nil
    end
    return byte_string_package
  end

  #---------------------------------------------------------------------------------------------------------
  # Convert the byte string back into a data array.
  def unpackage_data(received_data)
    case received_data
    when TCPSessionData::Package
      Logger.info("TCPSessionData", "Recieved an already packaged data byte string.")
      return received_data
    when String
      Logger.info("TCPSessionData", "Creating new Package from raw byte string data.")
      return Package.new(received_data)
    else
      Logger.warn("TCPSessionData", "Does not know what it recieved as data. (#{received_data.class})")
    end
    return nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a string byte message to the server connected to if any.
  def send_msg(sending_data, pack_data: true)
    return nil if closed?
    # validate message Object class type
    case sending_data
    when TCPSessionData::Package
      if sending_data.has_error?
        Logger.error("TCPSessionData", "Attempting to send a byte package with errors.")
        return nil
      else
        byte_string_package = sending_data.to_byte_s()
        socket_puts(byte_string_package)
      end
    when String
      if TCPSessionData::FORCE_ENCODING
        before_encoding = sending_data
        sending_data = before_encoding.encode(
          TCPSessionData::FORCE_ENCODING , undef: :replace, invalid: :replace, replace: ""
        )
        if before_encoding.length != sending_data.length
          Logger.error("TCPSessionData", "During send string encoding removed some bytes.")
        end
      end
      if pack_data
        Logger.info("TCPSessionData", "Packaging String data to send: (#{sending_data.inspect})")
        byte_string_package = package_data(sending_data)
        Logger.info("TCPSessionData", "send_msg() raw data: (#{byte_string_package.inspect})")
        socket_puts(byte_string_package)
      else
        Logger.info("TCPSessionData", "Sending a raw String: (#{sending_data.inspect})")
        socket_puts(sending_data)
      end
    else
      Logger.error("TCPSessionData", "Can only send String messages through the socket. not: #{sending_data.class}")
      return nil
    end
    # return success
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # Try catch error for sending with socket so application doens't crash if it fails to put sting data.
  # All outgoing data flows through here when using a TCPSessionData object.
  def socket_puts(string)
    Logger.debug("TCPSessionData", "Socket.puts raw String about to send. (#{string.inspect})")
    # do some checks on the argument provided before proceeding
    unless string.is_a?(String)
      Logger.error("TCPSessionData", "Can only Socket.puts String objects.")
      return false
    end
    if string.length > (TCPSessionData::USE_RAW_STRING_PACKAGE ? 512 : 1024) # max bytes able to send
      Logger.error("TCPSessionData", "Socket.puts String is too large to send.")
      return false
    end
    # attempt to send the message over network
    begin
      if TCPSessionData::USE_RAW_STRING_PACKAGE
        # Sending the raw bytes string does have random chance of an inproperly schedualed end-line flag.
        # An end-line string flag "\n" marks where a socket message stops. I think you can see the issue...
        @socket.puts(string)
      else
        # Convert the string of characters into an array, then pack that array into a string for a hex representation of
        # those byte characters. Doing this prevents the chances of sending bytes used internally for networks. The down
        # side of doing this is that the message size is halfed as it takes two characters to show a hex value for a byte.
        @socket.puts(string.bytes.pack("c*").unpack("H*").first())
      end
    # catch errors and if known to not be critical, handle in a safe way
    rescue => error
      case error
      when Errno::EPIPE
        Logger.error("TCPSessionData", "Can not send when socket is closed.")
      when Errno::ENOTCONN
        Logger.error("TCPSessionData", "Socket is open on this end, but the client session is not.")
      else
        Logger.error("TCPSessionData", "Write: #{error.inspect}")
      end
      return false
    end
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # Is blocking function, wait for a connected network session message. All incoming data flows through here.
  def await_data_msg(use_package = true)
    return nil if closed?
    begin
      # when a new message arives, remove the end-line flag of the string recieved
      response_string = @socket.gets()
      raise SocketClosedException.new() if response_string.nil?
      response_string.chomp() # <- always remove the messages end-line flag.
      # instead of sending raw bytes in the string message, send a hex string representating these bytes,
      # this requires an extra step in packaging the data if enabled and also doubles the sending string's size.
      unless TCPSessionData::USE_RAW_STRING_PACKAGE
        response_string = [response_string].pack('H*')
      end
    rescue => error
      case error
      when Errno::ECONNRESET
        Logger.warn("TCPSessionData", "Client forcibly closed connection.")
        return nil
      when SocketClosedException
        Logger.warn("TCPSessionData", "The other end of the socket forcibly closed its connection.")
        return nil
      else
        Logger.error("TCPSessionData", "Read: #{error}")
      end
    end
    # if connection is was still responsive, proccess their responces
    if response_string
      before_encoding = response_string
      sending_data = response_string.encode(
        TCPSessionData::FORCE_ENCODING , undef: :replace, invalid: :replace, replace: ""
      )
      if before_encoding.length != response_string.length
        Logger.error("TCPSessionData", "When recieving a new string encoding removed some bytes.")
      end
    else
      return nil
    end
    # return Object can be the raw byte String or a TCPSessionData::Package
    if use_package
      return unpackage_data(response_string)
    else
      return response_string
    end
  end

  #---------------------------------------------------------------------------------------------------------
  # Close the connection.
  def close()
    @socket.close() unless @socket.nil?
    @socket = nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Check if the socket it still in use.
  def closed?
    return @socket.nil?
  end

#===============================================================================================================================
  class SocketClosedException < StandardError
    def initialize(msg="Socket has reported back that it is closed.", exception_type="custom")
      @exception_type = exception_type
      super(msg)
    end
  end
end
