#===============================================================================================================================
# !!!   TCPsession.rb  | Manages a client session and unifies data work between transfers from the server.
#===============================================================================================================================
class TCPsession
  attr_accessor :username

  #--------------------------------------
  # Option to send raw byte strings instead of inflating by a factor of two and sending a hex string representation.
  # If you can manage to avoid end-line flags when packaging raw data then you can use raw strings. Otherwise its
  # recommended you instead send a string of characters to represent these bytes which later can be turned back into
  # a byte string where ever the network message is received. This means instead of a message of 1024 bytes, you 
  # can send a message of 512 bytes for a maximum payload size.
  USE_RAW_STRING_PACKAGE = false  # ** Default is 'false'.
  #--------------------------------------
  FORCE_ENCODING = Encoding::ASCII_8BIT
  # nil
  # Encoding::UTF_8
  # Encoding::ASCII
  # Encoding::ASCII_8BIT

#===============================================================================================================================
# Create the session and manage the packages of byte data strings sent across connected sockets.
#===============================================================================================================================
  def initialize(socket, username = "")
    @creation_time = Time.now.utc()
    @socket = socket
    @client_self = ClientPool::Client.new(username: username, session_pointer: self)
    # The first initialization will be local client, so that will be bound to the ClientPool to reference local Client
    # this means that the server will have many sessions with many pools with in them, but only the top pool is filled.
    # on the other end, the client subscribed to the server session only has one pool.
    @client_pool = ClientPool.new(self)
    request_sync_client()
  end

  #---------------------------------------------------------------------------------------------------------
  # Check if provided user ref_id is the same one as the local session.
  def is_self?(this_user_id = nil)
    return nil if @client_self.nil?
    return @client_self.ref_id == this_user_id
  end

  #---------------------------------------------------------------------------------------------------------
  # Get local self's public description shown between clients connected to the same server.
  def description()
    return @client_self
  end

  #---------------------------------------------------------------------------------------------------------
  # Return all the currently known clients.
  def get_client_pool()
    return @client_pool
  end

  #---------------------------------------------------------------------------------------------------------
  # Request a change to @client_self be synced by the server to other client sessions.
  def request_sync_client()
    Logger.info("TCPsession", "Local client is requesting a change to its public description. (#{@client_self.inspect})",
      tags: [:Network, :Package, :Client]
    )
    @client_pool.sync_client(@client_self)
  end

  #---------------------------------------------------------------------------------------------------------
  # Return a new Package object to load data into in preparation for sending over network session.
  def empty_data_package()
    return nil if @client_self.nil?
    return Package.new(nil, @client_self.ref_id)
  end

  #---------------------------------------------------------------------------------------------------------
  # Package send data array into a byte string depending on known types.
  def package_data(data_to_send)
    return nil if @client_self.nil?
    new_data_package = Package.new(nil, @client_self.ref_id)
    case data_to_send
    when String
      character_count = data_to_send.length()
      if character_count > 128
        Logger.warn("TCPsession", "Attempting to send a message that is too long. #{character_count}",
          tags: [:Network]
        )
        data_to_send = "'msg too long' #{character_count}"
      end
      byte_string_package = new_data_package.get_packed_string(Package::DATAMODE::STRING, data_to_send)
    else
      Logger.error("TCPsession", "Does not know how to send data of class type: #{data_to_send.class}",
        tags: [:Network]
      )
      return nil
    end
    return byte_string_package
  end

  #---------------------------------------------------------------------------------------------------------
  # Convert the byte string back into a data array.
  def unpackage_data(received_data)
    case received_data
    when TCPsession::Package
      Logger.info("TCPsession", "received an already packaged data byte string.",
        tags: [:Network, :Package]
      )
      return received_data
    when String
      Logger.info("TCPsession", "Creating new Package from raw byte string data.",
        tags: [:Network, :Package]
      )
      return Package.new(received_data)
    else
      Logger.warn("TCPsession", "Does not know what it received as data. (#{received_data.class})",
        tags: [:Network, :Package]
      )
    end
    return nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Send a string byte message to the server connected to if any.
  def send_msg(sending_data, pack_data: true)
    return nil if closed?
    # validate message Object class type
    case sending_data
    when TCPsession::Package
      if sending_data.has_error?
        Logger.error("TCPsession", "Attempting to send a byte package with errors.",
          tags: [:Network]
        )
        return nil
      else
        byte_string_package = sending_data.to_byte_s()
        socket_puts(byte_string_package)
      end
    when String
      if TCPsession::FORCE_ENCODING
        before_encoding = sending_data
        sending_data = before_encoding.encode(
          TCPsession::FORCE_ENCODING , undef: :replace, invalid: :replace, replace: ""
        )
        if before_encoding.length != sending_data.length
          Logger.error("TCPsession", "During send string encoding removed some bytes.",
            tags: [:Network]
          )
        end
      end
      if pack_data
        Logger.info("TCPsession", "Packaging String data to send: (#{sending_data.inspect})",
          tags: [:Network, :Package]
        )
        byte_string_package = package_data(sending_data)
        Logger.info("TCPsession", "send_msg() raw data: (#{byte_string_package.inspect})",
          tags: [:Network, :Package]
        )
        socket_puts(byte_string_package)
      else
        Logger.info("TCPsession", "Sending a raw String: (#{sending_data.inspect})",
          tags: [:Network, :Package]
        )
        socket_puts(sending_data)
      end
    else
      Logger.error("TCPsession", "Can only send String messages through the socket. not: #{sending_data.class}",
        tags: [:Network]
      )
      return nil
    end
    # return success
    return true
  end

  #---------------------------------------------------------------------------------------------------------
  # Try catch error for sending with socket so application doesn't crash if it fails to put sting data.
  # All outgoing data flows through here when using a TCPsession object.
  def socket_puts(string)
    Logger.debug("TCPsession", "Socket.puts raw String about to send. (#{string.inspect})",
      tags: [:Network]
    )
    # do some checks on the argument provided before proceeding
    unless string.is_a?(String)
      Logger.error("TCPsession", "Can only Socket.puts String objects.",
        tags: [:Network]
      )
      return false
    end
    if string.length > (TCPsession::USE_RAW_STRING_PACKAGE ? 512 : 1024) # max bytes able to send
      Logger.error("TCPsession", "Socket.puts String is too large to send.",
        tags: [:Network]
      )
      return false
    end
    # attempt to send the message over network
    begin
      if TCPsession::USE_RAW_STRING_PACKAGE
        # Sending the raw bytes string does have random chance of an improperly scheduled end-line flag.
        # An end-line string flag "\n" marks where a socket message stops. I think you can see the issue...
        @socket.puts(string)
      else
        # Convert the string of characters into an array, then pack that array into a string for a hex representation of
        # those byte characters. Doing this prevents the chances of sending bytes used internally for networks. The down
        # side of doing this is that the message size is halved as it takes two characters to show a hex value for a byte.
        @socket.puts(string.bytes.pack("c*").unpack("H*").first())
      end
    # catch errors and if known to not be critical, handle in a safe way
    rescue => error
      case error
      when Errno::EPIPE
        Logger.error("TCPsession", "Can not send when socket is closed.",
          tags: [:Network]
        )
      when Errno::ENOTCONN
        Logger.error("TCPsession", "Socket is open on this end, but the client session is not.",
          tags: [:Network]
        )
      else
        Logger.error("TCPsession", "Write: #{error.inspect}",
          tags: [:Network]
        )
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
      # when a new message arrives, remove the end-line flag of the string received
      response_string = @socket.gets()
      raise SocketClosedException.new() if response_string.nil?
      response_string.chomp() # <- always remove the messages end-line flag.
      # instead of sending raw bytes in the string message, send a hex string representing these bytes,
      # this requires an extra step in packaging the data if enabled and also doubles the sending string's size.
      unless TCPsession::USE_RAW_STRING_PACKAGE
        response_string = [response_string].pack('H*')
      end
    rescue => error
      case error
      when Errno::ECONNRESET
        Logger.warn("TCPsession", "Client forcibly closed connection.",
          tags: [:Network]
        )
        return nil
      when SocketClosedException
        Logger.warn("TCPsession", "The other end of the socket forcibly closed its connection.",
          tags: [:Network]
        )
        return nil
      when Errno::EPIPE
        Logger.error("TCPsession", "Socket connection between remote is broken.",
          tags: [:Network]
        )
        return nil
      else
        Logger.error("TCPsession", "Read: #{error.inspect}",
          tags: [:Network]
        )
      end
    end
    # if connection is was still responsive, process their responses
    if response_string
      before_encoding = response_string
      sending_data = response_string.encode(
        TCPsession::FORCE_ENCODING , undef: :replace, invalid: :replace, replace: ""
      )
      if before_encoding.length != response_string.length
        Logger.error("TCPsession", "When receiving a new string encoding removed some bytes.",
          tags: [:Network, :Package]
        )
      end
    else
      return nil
    end
    # return Object can be the raw byte String or a TCPsession::Package
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
