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

#===============================================================================================================================
module Configuration
  ROOT_DIR = File.expand_path('.',__dir__)
  PORT = 2000

  #---------------------------------------------------------------------------------------------------------
  # Get local subnet IP, (LAN)
  def self.getSelfIP()
    remote_ip = URI.open('http://whatismyip.akamai.com').read
    local_ip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
    return [remote_ip, local_ip]
  end
end
