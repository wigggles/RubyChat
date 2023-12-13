#!/usr/bin/env ruby
#===============================================================================================================================
# !!!   server.rb  | Starts and is the manager for the server service.
#-------------------------------------------------------------------------------------------------------------------------------
require './src/internal/Configuration.rb'

#===============================================================================================================================
if Configuration::CLI_MODE
  require 'socket'
  require './src/network/TCP/session.rb'
  require './src/network/TCP/server.rb'

  server = TCPserver.new()
  server.listen()
  
else # using GUI mode
  require './src/ApplicationWindow.rb'

  applicationGosuWindow = ApplicationWindow.new(true)
  applicationGosuWindow.show()
end

exit()
