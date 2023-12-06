#===============================================================================================================================
# !!!   Configuration.rb  | Provides initialization settings.
#-----------------------------------------------------------------------------------------------------------------------------
# Version 0.6
# Date: 12/06/2023
#-----------------------------------------------------------------------------------------------------------------------------
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
  DEBUG = false
  ROOT_DIR = File.expand_path('.',__dir__)
  PORT = 2000

  CLI_MODE = false  # Use comand line interface, or 'false' for Gosu GUI.

  # GUI mode settings:
  FULLSCREEN = false
  SCREEN_WIDTH = 640
  SCREEN_HEIGHT = 480

  #---------------------------------------------------------------------------------------------------------
  # Get local subnet IP, (LAN)
  def self.getSelfIP()
    remote_ip = URI.open('http://whatismyip.akamai.com').read
    local_ip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
    return [remote_ip, local_ip]
  end
end
