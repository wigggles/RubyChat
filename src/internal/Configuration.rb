#===============================================================================================================================
# !!!   Configuration.rb  | Provides initialization settings.
#-------------------------------------------------------------------------------------------------------------------------------
# This is the first object to be loaded when launching the application. It contains common settings and methods.
#
# Due to the nature of external IPs it is typically required to touch a remote and obtain the result.
#===============================================================================================================================
require 'set'
require 'open-uri'

Thread.report_on_exception = true # Threads report back fail

#===============================================================================================================================
module Configuration
  DEBUG = false # Display additional IP information.
  ROOT_DIR = File.expand_path('../',__dir__)
  PORT = 2000

  require "#{ROOT_DIR}/internal/Logger.rb" # Make things easier to debug and track with colors.

  #--------------------------------------
  # GUI mode settings:
  CLI_MODE    = false  # Use command line interface, or 'false' for Gosu GUI.
  FULL_SCREEN = false  # Start in Fullscreen mode, disables RESIZABLE setting.
  RESIZABLE   = true   # Can resize the application window.
  module ResolutionModes
    DESK_HDMED = [1920, 1080]
    DESK_HDSML = [1366,  768]
    DESK_LRG   = [1280, 1024]
    DESK_MED   = [1024,  768]
    DESK_SML   = [ 640,  480]
    MOBILE_LRG = [ 414,  736]
    MOBILE_MED = [ 390,  844]
    MOBILE_SML = [ 360,  800]
    MOBILE_MIN = [ 375,  667]
  end
  # To change startup resolution just swap out the below constant.
  INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT = ResolutionModes::DESK_MED

  GOSU_UPDATE_MS = 16.666666 # The milliseconds between Gosu::Window.update calls.

  #---------------------------------------------------------------------------------------------------------
  # Below is a list of publicly known 3rd party remote IP APIs.
  REMOTE_IP_API = {
    akamai:         "http://whatismyip.akamai.com",
    ipecho:         "http://ipecho.net/plain",
    icanhazip:      "http://icanhazip.com",
    ident:          "http://ident.me",
    whatsmyaddress: "http://bot.whatismyipaddress.com"
  }
  # Bellow sets which remote IP look up service to use when getting application IP.
  USE_REMOTE_LOOKUP = :akamai
  # Get local subnet IP, (LAN) and remote (Public) IP using 3rd party site API.
  def self.getSelfIP()
    begin
      local_ip  = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
      remote_ip = URI.open(REMOTE_IP_API[USE_REMOTE_LOOKUP]).read()
    rescue => error
      Logger.error("Configuration", "Could not resolve public/local IPs, 'No Internet'?"+
        "\n(#{error.inspect})",
        tags: [:Network]
      )
    end
    return [remote_ip, local_ip]
  end

  #---------------------------------------------------------------------------------------------------------
  # Attempt to generate new unique ids, uses a time based float. By default this id will be a String hex value.
  # Depending on mode, returns an integer or a long long integer to form a readable string twice the length
  # displaying the byte values or a packed string value consisting of the bytes raw ansi characters.
  # These IDs are then used to identify network elements for client data object's reference. Due to this,
  # its important to keep track with how many bytes are being packaged for object reference and generate
  # an ID matching the session-Package requirements. There is also a chance that the same value is drawn
  # twice or more, you'll need to plan for such cases so IDs stay unique.
  def self.generate_new_ref_id(as_string: true, micro: false, clamp: false, packed: false)
    # Generate a new id as a large 8 byte value which will be clamped down to 4 bytes
    # 42,949,672,950 is the maximum size of a 4 byte unsigned integer, this gets chomped later
    if clamp
      # A shift in power is done here before chunking a portion of the
      # integer's bytes to make the new reference ID.
      new_id = ((Time.now.to_f() * 10_000_000).round() % 42_949_672_950) # actually *4_294_967_295
    else
      # a time value is usually 8 bytes as a long long unsigned integer.
      # so do nothing to the new_id value, it will be less then 18_446_744_073_709_551_615
      new_id = (Time.now.to_f() * 10_000_000).round()
      # the upper bytes are not occupied in this century, so almost safe bet to drop a few.
      # generates upto 6 bytes total for a little extra uniqueness to ids over using 4 bytes
    end 
    # If using a semi human readable id that was generated, it needs to be at least 10 characters.
    if as_string
      # The ID is converted to base 16 hex, doubling its string length. A generalization of a poor probability
      # can be seen with only using a portion of the total available unique identifiers. Larger values also
      # require more bytes to package data when transporting it around.
      new_id = new_id.to_s(16)
      if micro # only grab 3 bytes (6 characters), quite high chances of generating an existing id
        # 'micro' can support 16_777_215 unique IDs, a thousandth used in one instance is 16_777 IDs.
        # Chances roll over every 
        new_id = new_id.slice(6...8).concat(new_id.slice(10...new_id.size))
      elsif clamp # only grab 4 bytes (8 characters), over time chances of a duplicate raise
        # 'clamp' can support 4_294_967_295 unique IDs, one thousandth odd is 4_294_967 IDs.
        # Chances roll over about once a minute.
        new_id = new_id.slice(1...9)
      else # use 5 bytes (10 characters), a bit more time based random for larger id pools
        # 'normal' can support 18_446_744_073_709_551_615, one thousandth odd is 18_446_744_073_709_551 IDs.
        # Chances roll over in about a day or so.
        new_id = new_id.slice(4...new_id.size)
      end
      # optionally, convert the hex string from the integer id hex readable string into a raw byte string halving
      # its size, however this makes the id's not human readable unless they are unpacked later. This packaging
      # requires that there be an even number of characters. One issue to keep in mind when working with raw bytes
      # is the potential to send them into terminal/console prints/puts and or socket issues with internal byte codes.
      # *NOTE* This is why sometimes its best to send a string of the bytes represented by 2 characters instead with
      # net traffic or saving to file space when working with raw byte file types.
      new_id = [new_id].pack('H*') if packed
    end
    # Even using the 4 byte system, one thousandth of the maximum number of IDs generated would still just
    # about support 500_000 objects comfortably.
    return new_id
  end
end
