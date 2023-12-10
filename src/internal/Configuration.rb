#===============================================================================================================================
# !!!   Configuration.rb  | Provides initialization settings.
#-------------------------------------------------------------------------------------------------------------------------------
# This is the first object to be loaded when launching the application. It contains common settings and methods.
#
# Due to the nature of external IPs it is typically required to touch a remote and obtain the result.
# Below is a list of publically known 3rd party remote IP APIs.
# http://whatismyip.akamai.com
# http://ipecho.net/plain
# http://icanhazip.com
# http://ident.me
# http://bot.whatismyipaddress.com
#===============================================================================================================================
require 'open-uri'

Thread.report_on_exception = true # Threads report back fail

#===============================================================================================================================
module Configuration
  DEBUG = false # Display additional IP information.
  ROOT_DIR = File.expand_path('.',__dir__)
  PORT = 2000

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
  SCREEN_WIDTH, SCREEN_HEIGHT = ResolutionModes::DESK_SML

  #---------------------------------------------------------------------------------------------------------
  # Get local subnet IP, (LAN)
  def self.getSelfIP()
    remote_ip = URI.open('http://whatismyip.akamai.com').read
    local_ip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
    return [remote_ip, local_ip]
  end

  #---------------------------------------------------------------------------------------------------------
  # Attempt to generate new unique ids, uses a time based float. By defualt this id will be a String hex value.
  def self.generate_new_ref_id(as_string = true)
    # Generate a new id as a large 8 byte value which will be clamped down to 4 bytes
    # 42,949,672,950 is the maximum size of a 4 byte unsigned integer
    new_id = ((Time.now.to_f() * 100_000_000_000).round() % 1_000_000_000_000_000_000)
    new_id = new_id % 42_949_672_950
    # If using a semi human readable id that was generated, it needs to be at least 10 byte characters.
    if as_string
      new_id = new_id.to_s(16).rjust(10, rand(0..10).to_s)
      new_id = new_id[0..10]
    end
    return new_id
  end
end
