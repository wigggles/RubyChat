#===============================================================================================================================
# !!!   TCPSessionData.rb  | Manages a client session and unifies data work between transfers from the server.
#===============================================================================================================================
class TCPSessionData
  attr_accessor :username
  FORCE_ENCODING = "ascii-8bit"

  #---------------------------------------------------------------------------------------------------------
  # The expanded more workable type of socket data. Gives the session byte data string workable structure.
  class Package
    BYTE_STRING = "La20ca*"
    # The above defines how to deal with the string stream of data.
    #
    #    L    | 32-bit unsigned creation time edian
    #    a20  | 20 character long username
    #    c    | 8-bit signed (signed char) mode integer
    #    a*   | take whats left, an arbritray length 'message' as string value
    #--------------------------------------
    module DATAMODE
      STRING = 0    # This mode is the basic one, it just uses the string as a string.
    end
    #--------------------------------------
    attr_reader :time_stmp, :user_id, :data_mode, :data
    def initialize(byte_string = nil, user_id = nil)
      @user_id = user_id || ""
      unpack_byte_string(byte_string) unless byte_string.nil?
    end
    #--------------------------------------
    # If data type is for a String, package as such.
    def pack_dt_string(string = nil)
      @time_stmp = Time.new()
      @data_mode = DATAMODE::STRING
      @data = string unless string.nil?
      return [@time_stmp.to_i, @user_id, @data_mode, @data].pack(Package::BYTE_STRING)
    end
    #--------------------------------------
    # Depending on defined mode get the data package byte string.
    def get_packed_string(data_mode = DATAMODE::STRING, for_data = nil)
      @data_mode = data_mode
      case @data_mode
      when DATAMODE::STRING
        case for_data
        when String
          return pack_dt_string(for_data)
        else
          puts("ERROR: TCPSessionData Package is in String mode but did not recieve a string.")
        end
      else
        puts("WARN: TCPSessionData Package is in an unkown data mode. #{@data_mode.class}")
        return nil
      end
    end
    #--------------------------------------
    # Unpack the byte string back into an array of objects.
    def unpack_byte_string(byte_string)
      #puts("TCPSessionData::Package byte string value (#{byte_string.inspect})")
      data_array = byte_string.unpack(Package::BYTE_STRING)
      # validate this new Array has the correct data form
      @time_stmp = Time.at(data_array[0])              # time message was created
      @user_id   = data_array[1].chomp().delete("\00") # client_id with byte padding removed
      @data_mode = data_array[2].to_i                  # extra data packaging mode
      @data      = data_array[3].chomp()               # extra/rest of data bytes sent
      #puts("TCPSessionData::Package Array (#{data_array.inspect})")
      #puts("TCPSessionData::Package state (#{[@time_stmp, @user_id, @data_mode, @data]})")
    end
    #--------------------------------------
    # Return the package byte header and its raw data as an Array object.
    def to_a()
      return [@time_stmp, @user_id, @data_mode, @data]
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
    @creation_time = Time.new()
    @username = username
    @socket = socket
  end

  #---------------------------------------------------------------------------------------------------------
  # Package send data array into a byte string depending on kown types.
  def package_data(data_to_send = "")
    new_data_package = Package.new(nil, @username)
    case data_to_send
    when String
      character_count = data_to_send.length()
      if character_count > 128
        puts("WARN: Attempting to send a message that is too long. #{character_count}")
        data_to_send = "'msg too long' #{character_count}"
      end
      byte_string_package = new_data_package.get_packed_string(Package::DATAMODE::STRING, data_to_send)
    else
      puts("ERROR: TCPSessionData does not know how to send data of class type: #{data_to_send.class}")
      return nil
    end
    return byte_string_package
  end

  #---------------------------------------------------------------------------------------------------------
  # Convert the byte string back into a data array.
  def unpackage_data(received_data)
    case received_data
    when TCPSessionData::Package
      #puts("DEBUG: TCPSessionData recieved an already packaged data byte string.")
      return received_data
    when String
      #puts("DEBUG: TCPSessionData creating new Package from raw byte string data.")
      return Package.new(received_data)
    else
      puts("WARN: TCPSessionData does not know what it recieved as data. (#{received_data.class})")
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
      byte_string_package = sending_data.to_byte_s()
      @socket.puts(byte_string_package)
    when String
      sending_data = sending_data.encode(TCPSessionData::FORCE_ENCODING, undef: :replace, invalid: :replace, replace: "")
      if pack_data
        byte_string_package = package_data(sending_data)
        #puts("Raw: #{byte_string_package.inspect}")
        @socket.puts(byte_string_package)
      else
        @socket.puts(sending_data)
      end
    else
      puts("ERROR: TCPSessionData can only send String messages through the socket. not: #{sending_data.class}")
      return nil
    end
    # return success
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # Is blocking function, wait for server message. * CLI only
  def await_msg(use_package = true)
    return nil if closed?
    begin
      response_string = @socket.gets()
    rescue => error
      case error
      when Errno::ECONNRESET
        #puts("DEBUG: Client forcibly closed connection.")
        return nil
      else
        puts(error)
      end
    end
    # if connection is was still responsive, proccess their responces
    if response_string
      response_string = response_string.encode(TCPSessionData::FORCE_ENCODING, undef: :replace, invalid: :replace, replace: "")
      response_string = response_string.chomp()
    else
      return nil
    end
    return unpackage_data(response_string) if use_package
    return response_string
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
