#===============================================================================================================================
# !!!   client.rb  | Starts and manages a client instance that communicates with the server service.
#-------------------------------------------------------------------------------------------------------------------------------
require './src/internal/Configuration.rb'

#===============================================================================================================================
# Construct a new client and start a connection with server.
username = ARGV[0]
unless username
  puts("You must provide a username as a runtime argument.")
  exit()
end

if Configuration::CLI_MODE
  require 'socket'
  require './src/network/TCPSessionData.rb'
  require './src/network/TCPclient.rb'

  client = TCPclient.new("localhost")
  client.start_session(username)
  client.connect()

else # using GUI mode
  require './src/ApplicationWindow.rb'

  applicationGosuWindow = ApplicationWindow.new()
  applicationGosuWindow.show()
end

exit()
