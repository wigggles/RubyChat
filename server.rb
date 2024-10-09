#!/usr/bin/env ruby
#=====================================================================================================================
# !!!   server.rb  | Starts and is the manager for the server service.
#-----------------------------------------------------------------------------------------------------------------------
require './src/internal/Configuration'

#=====================================================================================================================
if Configuration::CLI_MODE
  require 'socket'
  require './src/network/TCP/session'
  require './src/network/TCP/server'

  server = TCPserver.new
  server.listen

else # using GUI mode
  require './src/ApplicationWindow'

  applicationGosuWindow = ApplicationWindow.new(true)
  applicationGosuWindow.show
end

exit
