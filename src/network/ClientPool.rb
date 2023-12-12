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
    Logger.info("ClientPool", "New client pool created for network session."+
      "\nclient ref_id: (#{@net_session.description.ref_id}):"+
      "\nsession: (#{@net_session.inspect})"+
      "\ndescription: (#{@net_session.description.inspect})",
      tags: [:Client]
    )
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
  # Add a client to the pool, if it doesn't exist already create a new ClientPool::Client object.
  def add_new(client)
    Logger.debug("ClientPool", "Adding to the client pool, currently swimming:[#{@clients.size}]"+
      "\nnew: (#{client.inspect})",
      tags: [:Network, :Client]
    )
    case client
    when TCPsession
      new_client = client.description
    when ClientPool::Client
      new_client = client
    end
    # make sure the client doesn't already exist in the pool
    if find_client(by: :ref_id, search_term: new_client.ref_id)
      Logger.warn("ClientPool", "Attempting to add a client already in the pool."+
        "\nclient: (#{client.inspect})",
        tags: [:Client]
      )
    else
      @clients << new_client
      return new_client
    end
    Logger.error("ClientPool", "Failed to add new client: (#{client.inspect})",
      tags: [:Client]
    )
    return false
  end
  #---------------------------------------------------------------------------------------------------------
  def each()
    for client in @clients
      yield(client)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def find_client(by: :ref_id, search_term: '')
    Logger.debug("ClientPool", "Searching client pool for: [#{by}](#{search_term})",
      tags: [:Client]
    )
    if search_term.nil?
      puts("\n\nHere\n\n")
    end
    case by
    when :ref_id
      located = @clients.select { |client| client.ref_id == search_term }
    when :username
      located = @clients.select { |client| client.username == search_term }
    end
    return nil if located.nil?
    sml_string_list = located.map() { |client|
      [client.ref_id, client.username]
    }
    Logger.info("ClientPool", "While searching found clients: [#{by}](#{search_term})"+
      "\nlocated[#{sml_string_list.size}]: (#{sml_string_list.inspect()})",
      tags: [:Client]
    )
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
    else
      update_client(found_client, client)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def update_client(found_client, client)
    Logger.info("ClientPool", "Updating client description:"+
      "\nOld: (#{found_client.inspect})"+
      "\nNew: (#{client.inspect})",
      tags: [:Client]
    )

  end
  #---------------------------------------------------------------------------------------------------------
  # Recived a request to sync clients from server session.
  def sync_requested(package)
    sync_data = package.expand_client_data()
    Logger.debug("ClientPool", "Local has recieved request to sync with client pool."+
      "\npackage: (#{package.inspect})"+
      "\nclient_data: (#{sync_data.inspect})",
      tags: [:Network, :Client]
    )
    # update the local client list with the recived descriptions
    if sync_data.is_a?(Array)
      case sync_data[1]
      when Array
        sync_data[1].each() { |data|
          ref_id, username = data
          sync_client(Client.new(ref_id: ref_id, username: username))
        }
        return true
      end
    end
    Logger.error("ClientPool", "Recieved request to sync pool but it's data was malformed."+
      "\vpackage: (#{package.inspect})"+
      "\vsync_data: (#{sync_data})",
      tags: [:Client]
    )
    return nil
  end
  #---------------------------------------------------------------------------------------------------------
  # Pack up the clients into an array for byte string conversion.
  def pack_array_to_send()
    return @clients.map() { |client|
      [client.ref_id, client.username]
    }
  end
end
