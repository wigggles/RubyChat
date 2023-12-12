#===============================================================================================================================
# !!!  Tests.rb |  Run a few tests.
#===============================================================================================================================
require './src/internal/Configuration.rb'

module Tests
  MAX_NEW_ID_TRYS = 1_000_000
  #---------------------------------------------------------------------------------------------------------
  # Generate a bunch of new id's and check to see if any duplicates are found.
  def self.test_random_ids()
    puts("Checking if able to reliably generate random ids.")
    trys = 0
    ids  = Set.new()
    dupe = false
    new_id = nil
    start_time = Time.now
    while !dupe
      threads = []
      # Max number of threads running at the same time is limited to the system environment, this requests 10 "jobs"
      10.times() { |t|
        thread = Thread.new { # each thread generates 10 new ids
          1000.times() { |i| 
            #new_id = Configuration.generate_new_ref_id(as_string: false)
            new_id = Configuration.generate_new_ref_id(as_string: true)
            #new_id = Configuration.generate_new_ref_id(as_string: true, packed: true).unpack('H*')[0]
            dupe = new_id unless ids.add?(new_id)
          }
        }
        # collect the threads for joining together later
        threads << thread
      }
      threads.each() { |thread| thread.join() } # wait here to sync all thread "job" work is done
      trys = ids.size
      puts("Trys: (#{trys}) an id: [#{new_id}]") if (trys % 10_000) == 0
      break if trys >= Tests::MAX_NEW_ID_TRYS
    end
    puts("Test is over, took (#{(Time.now - start_time).round()}) seconds")
    if dupe
      puts("Found a dupe id generated in #{trys} trys for (#{dupe}).")
    else
      puts("Tried #{trys} times but did not find any duplicate ids.")
    end
  end
  #---------------------------------------------------------------------------------------------------------
  # Figure out what the best way of packaging a Time object is.
  def self.test_time()
    time_now = Time.new().getgm()
    puts("Packing Time object: (#{time_now.to_f})")
    test_packing_time(time_now)
  end
  #---------------------------------------------------------------------------------------------------------
  def self.test_hex_pacakge()
    sample_package = "\xF6\x030y\x9By<\x00\x00\x00\x00\x00\x00\x00\x00Server shut down, goodbye 0 clients!"
    puts("Test bytes string to hex string.")
    puts("(#{sample_package})")
    puts("(#{sample_package.inspect})")
    hex_string = sample_package.bytes.pack("c*").unpack("H*").first()
    puts("(#{hex_string})")
    hex_unpacked = [hex_string].pack('H*')
    puts("(#{hex_unpacked})")
    puts("(#{hex_unpacked.inspect})")
  end
  #---------------------------------------------------------------------------------------------------------
  def self.test_packing_time(time_object)
    %w(d D f F e E g G q Q).each { |flag|
      puts("Using mode: (#{flag})")
      packaged, unpacked = test_pack_mode(flag, time_object)
      puts("\packaged: (#{packaged.inspect}")
      puts("\tunpacked: (#{unpacked.inspect}")
      puts("")
    }
  end
  #---------------------------------------------------------------------------------------------------------
  def self.test_pack_mode(flag, use_time)
    case flag
    when 'q', 'Q'
      packaged = [use_time.to_f * 10000000].pack(flag)
      unpacked = packaged.unpack(flag).first() / 10000000
    else # normal float
      packaged = [use_time.to_f].pack(flag)
      unpacked = packaged.unpack(flag)
    end
    return [packaged, unpacked]
  end
end

puts("Running some tests:")

Tests.test_time()
Tests.test_hex_pacakge()
Tests.test_random_ids()

puts("Tests have finished.")
