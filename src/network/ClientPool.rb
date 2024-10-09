#=====================================================================================================================
# !!!   ClientPool.rb  |  Where all the clients get to swim together.
#=====================================================================================================================
class ClientPool
  # Additional package flags for arriving data sub packaged types.
  module DATAMODE
    ALL_CLIENTS = 0
  end

  #---------------------------------------------------------------------------------------------------------
  # Manageable client object.
  class Client
    attr_reader :ref_id, :username, :session_pointer

    #--------------------------------------
    def initialize(ref_id: nil, username: '', session_pointer: nil)
      @ref_id = ref_id || Configuration.generate_new_ref_id
      @username = username
      @session_pointer = session_pointer
    end

    #--------------------------------------
    def set_ref_id(new_id)
      return nil unless new_id.is_a?(String)

      if new_id.length < TCPsession::Package::CLIENT_ID_SIZE
        Logger.error('ClientPool::Client', "New Client ref_id:(#{new_id.inspect}) doesn't match length.",
                     tags: [:Client])
        return nil
      end
      ref_id = new_id[0...TCPsession::Package::CLIENT_ID_SIZE]
      Logger.info('ClientPool::Client', "Changing Client ref_id:(#{@ref_id.inspect}) to:(#{ref_id.inspect})",
                  tags: [:Client])
      @ref_id = ref_id
      @ref_id
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
    Logger.info('ClientPool', 'New client pool created for network session.' +
      "\nclient ref_id: (#{@net_session.description.ref_id}):" +
      "\nsession: (#{@net_session.inspect})" +
      "\ndescription: (#{@net_session.description.inspect})",
                tags: [:Client])
  end

  #---------------------------------------------------------------------------------------------------------
  def count
    @clients.count
  end

  #---------------------------------------------------------------------------------------------------------
  def session
    @net_session
  end

  #---------------------------------------------------------------------------------------------------------
  # Add a client to the pool, if it doesn't exist already create a new ClientPool::Client object.
  def add_new(client_session)
    case client_session
    when TCPsession
      new_client = client_session.description
    when ClientPool::Client
      new_client = client_session
    end
    Logger.debug('ClientPool', "Attempting to add client with ref_id:(#{new_client.ref_id}) into the session pool." +
      "\ncurrently swimming: [#{@clients.size}]" +
      "\nnew session: (#{client_session.inspect})",
                 tags: %i[Network Client])
    # make sure the Client doesn't already exist in the pool
    if find_client(by: :ref_id, search_term: new_client.ref_id)
      Logger.warn('ClientPool', "Tried to add a Client already in the pool. ref_id:(#{new_client.ref_id})" +
        "\nsession: (#{client_session.inspect})",
                  tags: [:Client])
    else
      @clients << new_client
      return new_client
    end
    Logger.error('ClientPool', 'Failed to add new Client into session pool.' +
      "\nref_id:(#{new_client.ref_id}) username:(#{new_client.username})" +
      "\nclient: (#{client_session.inspect})",
                 tags: [:Client])
    nil
  end

  #---------------------------------------------------------------------------------------------------------
  def each
    for client in @clients
      yield(client)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def find_client(by: :ref_id, search_term: '')
    unless search_term.is_a?(String)
      Logger.warn('ClientPool', "Searching client pool requires a String as the search_term. (#{search_term.inspect})",
                  tags: [:Client])
      return nil
    end
    Logger.debug('ClientPool', "Searching client pool for: [#{by}](#{search_term.inspect})",
                 tags: [:Client])
    puts("\n\nHere\n\n") if search_term.nil?
    case by
    when :ref_id
      located = @clients.select { |client| client.ref_id == search_term }
    when :username
      located = @clients.select { |client| client.username == search_term }
    end
    # process Array of any found matches
    return nil if located.nil?

    sml_string_list = located.map do |client|
      [client.ref_id, client.username]
    end
    Logger.info('ClientPool',
                "While searching found [#{sml_string_list.size}] clients for:[#{by}](#{search_term.inspect})" +
                "\nlocated: (#{sml_string_list.inspect})",
                tags: [:Client])
    # only return the first Client found if any had been found
    return located[0] if located.length > 0

    nil
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
    if found_client
      update_client(found_client, client)
    else
      add_new(client)
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def update_client(found_client, client)
    Logger.info('ClientPool', 'Updating client description:' +
      "\nOld: (#{found_client.inspect})" +
      "\nNew: (#{client.inspect})",
                tags: [:Client])
  end

  #---------------------------------------------------------------------------------------------------------
  # Received a request to sync clients from server session.
  def sync_requested(package)
    sync_data = package.expand_client_data
    Logger.debug('ClientPool', 'Local has received request to sync with client pool.' +
      "\npackage: (#{package.inspect})" +
      "\nclient_data: (#{sync_data.inspect})",
                 tags: %i[Network Client])
    # update the local client list with the received descriptions
    if sync_data.is_a?(Array)
      case sync_data[1]
      when Array
        sync_data[1].each do |data|
          ref_id, username = data
          sync_client(Client.new(ref_id: ref_id, username: username))
        end
        return true
      end
    end
    Logger.error('ClientPool', "received request to sync pool but it's data was malformed." +
      "\vpackage: (#{package.inspect})" +
      "\vsync_data: (#{sync_data})",
                 tags: [:Client])
    nil
  end

  #---------------------------------------------------------------------------------------------------------
  # Pack up the clients into an array for byte string conversion.
  def pack_array_to_send
    @clients.map do |client|
      [client.ref_id, client.username]
    end
  end
end
