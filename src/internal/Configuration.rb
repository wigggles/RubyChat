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
  CLI_MODE   = false  # Use comand line interface, or 'false' for Gosu GUI.
  FULLSCREEN = false
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
  # To change resolutions just swap out the below constant.
  SCREEN_WIDTH, SCREEN_HEIGHT = ResolutionModes::DESK_MED

  #---------------------------------------------------------------------------------------------------------
  # Below is a list of publically known 3rd party remote IP APIs.
  REMOTE_IP_API = {
    akamai:         "http://whatismyip.akamai.com",
    ipecho:         "http://ipecho.net/plain",
    icanhazip:      "http://icanhazip.com",
    ident:          "http://ident.me",
    whatsmyaddress: "http://bot.whatismyipaddress.com"
  }
  # Get local subnet IP, (LAN) and remote (Public) IP using 3rd party site API.
  def self.getSelfIP()
    begin
      local_ip  = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
      remote_ip = URI.open(REMOTE_IP_API[:akamai]).read()
    rescue => error
      Logger.error("Configuration", "Could not resolve public/local IPs, 'No Internet'?"+
        "\n(#{error.inspect})",
        tags: [:Network]
      )
    end
    return [remote_ip, local_ip]
  end

  #---------------------------------------------------------------------------------------------------------
  # Attempt to generate new unique ids, uses a time based float. By defualt this id will be a String hex value.
  # Depending on mode, returns an integer or a long long integer to form a readable string twice the length
  # displaying the byte values or a packed string value consisting of the bytes raw ansii characters.
  # These IDs are then used to identify network elements for client data object's refrence. Due to this,
  # its important to keep track with how many bytes are being packaged for object refrence and generate
  # an ID matching the session-Package requirements. There is also a chance that the same value is drawn
  # twice or more, you'll need to plan for such cases so ID's stay unique.
  def self.generate_new_ref_id(as_string: true, clamp: false, packed: false)
    # Generate a new id as a large 8 byte value which will be clamped down to 4 bytes
    # 42,949,672,950 is the maximum size of a 4 byte unsigned integer, this gets chomped later
    if clamp
      new_id = ((Time.now.to_f() * 10_000_000).round() % 42_949_672_950)
    else
      # a time value is usually 8 bytes as a long long unsigned integer.
      # so do nothing to the new_id value, it will be less then 18_446_744_073_709_551_615
      new_id = (Time.now.to_f() * 10_000_000).round()
      # the upper bytes are not occupied in this century, so almost safe bet to drop a few.
      # generates upto 6 bytes total for a little extra uniqueness to ids over using 4 bytes
    end 
    # If using a semi human readable id that was generated, it needs to be at least 10 characters.
    if as_string
      # The ID is converted to base 16 hex, doubling its string length
      new_id = new_id.to_s(16)
      if clamp # only grab 4 bytes (8 characters), over time chances of a duplicate raise
        new_id = new_id.slice(1...9)
      else # use 5 bytes (10 characters), a bit more time based random for larger id pools
        new_id = new_id.slice(4...new_id.size)
      end
      # optionally, convert the hex string from the integer id hex readable string into a raw byte string halfing
      # its size, however this makes the id's not human readable unless they are unpacked later. This packaging
      # requires that their be an even number of characters
      new_id = [new_id].pack('H*') if packed
    end
    return new_id
  end
end
