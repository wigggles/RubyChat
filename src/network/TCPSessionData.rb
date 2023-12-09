#===============================================================================================================================
# !!!   TCPSessionData.rb  | Manages a client session and unifies data work between transfers from the server.
#===============================================================================================================================
class TCPSessionData
  attr_accessor :username

  FORCE_ENCODING = Encoding::ASCII_8BIT
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
    BYTE_STRING = "q Z20 q n a*"
    ARRAY_LENGTH = 5
    # The above defines how to deal with the string stream of data.
    #
    #    q    | 8-byte integer  | local creation time edian.
    #    Z20  | 20 char bytes   | originating user id.
    #    q    | 8-byte integer  | server touched time edian.
    #    n    | 2-byte signed   | mode integer.
    #    a*   | take whats left | an arbritray length 'message' as a byte string value.
    #--------------------------------------
    BYTE_OBJECT = "L L L n a*"
    OBJECT_LENGTH = 5
    # After using the BYTE_STRING to define common data, perform additonal proccessing.
    #
    #    L    | 4-byte unsigned | object refrence ID.
    #    L    | 4-byte unsigned | object X world position.
    #    L    | 4-byte unsigned | object Y world position.
    #    n    | 2-byte signed   | type integer.
    #    a*   | take whats left | an arbritray length byte string.
    #--------------------------------------
    # It's crude but effective to count up using constants.
    module DATAMODE
      STRING = 0    # This mode is the basic one, it just uses the string as a string.
      OBJECT = 1    # This mode performs additional variable proccessing for generic data.
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
      when DATAMODE::OBJECT
        return false unless @data.is_a?(Array)
        return false unless @data.length == Package::OBJECT_LENGTH
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
    # Depending on defined mode get the data package byte string. This string is ready to send over socket sessions.
    def get_packed_string(data_mode = nil, for_data = nil)
      @data_mode = data_mode unless data_mode.nil?
      @data = for_data unless for_data.nil?
      case @data_mode
      when DATAMODE::STRING
        case @data
        when String
          return pack_dt_string()
        else
          Logger.error("TCPSessionData::Package", "In String mode but did not recieve a String.")
        end
      when DATAMODE::OBJECT
        case @data
        when Array
          return pack_dt_object()
        else
          Logger.error("TCPSessionData::Package", "In Object mode but did not recieve an Array.")
        end
      else
        Logger.warn("TCPSessionData::Package", "In an unkown data mode. #{@data_mode.class}")
        return nil
      end
    end
    #--------------------------------------
    # Unpack the byte string back into an array of objects.
    def unpack_byte_string(byte_string)
      Logger.info("TCPSessionData::Package", "Unpacking byte string value (#{byte_string.inspect})")
      data_array = byte_string.unpack(Package::BYTE_STRING)
      Logger.info("TCPSessionData::Package", "Unpacked String byte array (#{data_array.inspect})")
      # validate this new Array has the correct data form
      begin
        ct_time = (data_array[0] / 10000000.0)
        @created_time     = Time.at(ct_time)                    # local time message was created
        @user_id          = data_array[1].chomp().delete("\00") # client_id with byte padding removed
        sv_time = (data_array[2] / 10000000.0)
        @srvr_time_stmp   = Time.at(sv_time)                    # time from server
        @data_mode        = data_array[3].to_i                  # extra data packaging mode
        @data             = data_array[4].chomp()               # extra/rest of data bytes sent
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
      when DATAMODE::OBJECT
        @data = @data.unpack(Package::BYTE_OBJECT)
        unless @data.length != Package::OBJECT_LENGTH
          Logger.warn("TCPSessionData::Package", "DATAMODE::OBJECT package is malformed.")
        end
      else
        Logger.error("TCPSessionData::Package", "In an unkown DATAMODE (#{@data_mode})")
      end
      Logger.debug("TCPSessionData::Package", "Unpacked Array (#{data_array.inspect})")
      Logger.info("TCPSessionData::Package", "Unpacked state (#{self.inspect})")
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
      return pack_dt_string()
    end
  end

#===============================================================================================================================
# Create the session and manage the packages of byte data strings sent accross connected sockets.
#===============================================================================================================================
  def initialize(socket, username = "")
    @creation_time = Time.now.utc()
    @username = username
    @socket = socket
  end

  #---------------------------------------------------------------------------------------------------------
  # Return a new Package object to load data into in preperation for sending over network session.
  def empty_data_package()
    return Package.new(nil, @username)
  end

  #---------------------------------------------------------------------------------------------------------
  # Package send data array into a byte string depending on kown types.
  def package_data(data_to_send)
    new_data_package = Package.new(nil, @username)
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
      Logger.debug("TCPSessionData", "Recieved an already packaged data byte string.")
      return received_data
    when String
      Logger.debug("TCPSessionData", "Creating new Package from raw byte string data.")
      return Package.new(received_data)
    else
      Logger.warn("TCPSessionData", "Does not know what it recieved as data. (#{received_data.class})")
    end
    return nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a string byte message to the server connected to if any.
  def send_msg(sending_data, pack_data = true)
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
      Logger.info("TCPSessionData", "Packaging String data to send: (#{sending_data.inspect})")
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
        byte_string_package = package_data(sending_data)
        Logger.info("TCPSessionData", "send_msg() raw data: (#{byte_string_package.inspect})")
        socket_puts(byte_string_package)
      else
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
  def socket_puts(string)
    begin
      @socket.puts(string)
    rescue => error
      case error
      when Errno::EPIPE
        Logger.error("TCPSessionData", "Can not send when socket is closed.")
      else
        Logger.error("TCPSessionData", "Write: #{error}")
      end
      return false
    end
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # Is blocking function, wait for server message. * CLI only
  def await_data_msg(use_package = true)
    return nil if closed?
    begin
      response_string = @socket.gets()
    rescue => error
      case error
      when Errno::ECONNRESET
        Logger.debug("TCPSessionData", "Client forcibly closed connection.")
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
end
