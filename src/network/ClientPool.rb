#===============================================================================================================================
# !!!   ClientPool.rb  |  Where all the clients get to swim together.
#===============================================================================================================================
class ClientPool
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
    Logger.debug("ClientPool", "New client pool created: (#{@net_session.inspect})")
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
  def add_new(client_session)
    case client_session
    when TCPSessionData
      new_client = Client.new(session_pointer: client_session)
      @clients << new_client
      Logger.debug("ClientPool", "New client was added into the pool: (#{new_client.inspect})")
      return true
    end
    Logger.ERROR("ClientPool", "Failed to add new client: (#{client_session.inspect})")
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
end
