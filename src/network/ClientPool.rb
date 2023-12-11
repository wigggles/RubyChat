#===============================================================================================================================
# !!!   ClientPool.rb  |  Where all the clients get to swim together.
#===============================================================================================================================
class ClientPool
  module DATAMODE
    ALL_CLIENTS = 0
  end
  #---------------------------------------------------------------------------------------------------------
  # Managable client object.
  class Client
    attr_reader :ref_id, :username, :session_pointer
    #--------------------------------------
    def initialize(ref_id: nil, username: "", session_pointer: nil)
      @ref_id = ref_id || Configuration.generate_new_ref_id()
      @username = username
      @session_pointer = session_pointer
    end
    #--------------------------------------
    def set_name(requested_name)
      @username = requested_name
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def initialize(net_session)
    @net_session = net_session
    @clients = []
    Logger.info("ClientPool", "New client pool created with session: (#{@net_session.inspect})")
  end
  #---------------------------------------------------------------------------------------------------------
  def count()
    return @clients.count()
  end
  #---------------------------------------------------------------------------------------------------------
  def session()
    return @net_session
  end
  #---------------------------------------------------------------------------------------------------------
  def add_new(client)
    Logger.debug("ClientPool", "Adding to the client pool. [#{@clients.size}] (#{client.inspect})")
    case client
    when TCPsession
      new_client = Client.new(session_pointer: client)
      @clients << new_client
      return new_client
    when ClientPool::Client
      @clients << client
      return client
    end
    Logger.ERROR("ClientPool", "Failed to add new client: (#{client.inspect})")
    return false
  end
  #---------------------------------------------------------------------------------------------------------
  def each()
    for client in @clients
      yield(client)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def find_client(by: :id, search_term: '')
    case by
    when :id
      located = @clients.select { |client| client.ref_id == search_term }
    when :name
      located = @clients.select { |client| client.username == search_term }
    end
    return nil if located.nil?
    return located[0] if located.length > 0
    return nil
  end
  #---------------------------------------------------------------------------------------------------------
  def delete(ref_id)
    found_client = find_client(search_term: ref_id)
    @clients.delete(found_client) if find_client
  end
  #---------------------------------------------------------------------------------------------------------
  # Sync client that matches same ref_id, if no match add to pool.
  def sync_client(client)
    found_client = find_client(search_term: client.ref_id)
    unless found_client
      add_new(client)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  # Recived a request to sync clients from server session.
  def sync_requested(package)
    sync_data = package.client_data()
    Logger.warn("ClientPool", "Local has recieved request to sync with client pool."+
      "\npackage: (#{package.inspect})"+
      "\nclient_data: (#{sync_data.inspect})"
    )
    #@@client_pool
  end
  #---------------------------------------------------------------------------------------------------------
  # Pack up the clients into an array for byte string conversion.
  def pack_array_to_send()
    return @clients.map() { |client|
      [client.ref_id, client.username]
    }
  end
end
