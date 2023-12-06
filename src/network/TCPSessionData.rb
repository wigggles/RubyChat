#===============================================================================================================================
# !!!   TCPSessionData.rb  | Manages a client session and how data is transfered between the server.
#-----------------------------------------------------------------------------------------------------------------------------
# Version 0.6
# Date: 12/06/2023
#-----------------------------------------------------------------------------------------------------------------------------
class TCPSessionData
  attr_accessor :username

  DATA_PACKAGE = "La20a*"
  # 32-bit unsigned creation time edian
  # 20 character long username
  # arbritray length message string value

  #---------------------------------------------------------------------------------------------------------
  def initialize(socket, username = "")
    @creation_time = Time.new()
    @username = username
    @socket = socket
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a raw string message to the server.
  def send_msg(msg, pack_data = true)
    return nil if closed?
    msg = msg.encode("ascii-8bit", undef: :replace, invalid: :replace, replace: "")
    if pack_data
      byte_string = package_data(msg)
      #puts("Raw: #{byte_string.inspect}")
      @socket.puts(byte_string)
    else
      @socket.puts(msg)
    end
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # Is blocking function, wait for server message.
  def await_msg(unpackage = true)
    return nil if closed?
    begin
      response_string = @socket.gets()
    rescue => error
      case error
      when Errno::ECONNRESET
        puts("Client forcibly closed connection.")
        return nil
      else
        puts(error)
      end
    end
    # if client is was still responsive, proccess responce
    if response_string
      response_string = response_string.encode("ascii-8bit", undef: :replace, invalid: :replace, replace: "")
      response_string = response_string.chomp()
    else
      return nil
    end
    return unpackage_data(response_string) if unpackage
    return response_string
  end

  #---------------------------------------------------------------------------------------------------------
  # Package send data array into a byte string.
  def package_data(send_msg = "")
    character_count = send_msg.length()
    if character_count > 128
      puts("ERROR! Attempting to send a message that is too long. #{character_count}")
      send_msg = "'msg too long' #{character_count}"
    end
    data_package = [@creation_time.to_i, @username, send_msg]
    byte_string = data_package.pack(DATA_PACKAGE)
    return byte_string
  end

  #---------------------------------------------------------------------------------------------------------
  # Convert the byte string back into a data array.
  def unpackage_data(received_data = "")
    data = received_data.unpack(DATA_PACKAGE)
    data[0] = Time.at(data[0])
    data[1] = data[1].chomp().delete("\00") # remove byte padding
    data[2] = data[2].chomp()
    # data = [creation_time, username, message_string]
    return data
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
