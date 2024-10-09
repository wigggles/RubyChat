#!/usr/bin/env ruby
#=====================================================================================================================
# !!!  GeneralTests.rb |  Run a few tests.
#-----------------------------------------------------------------------------------------------------------------------
# Sometimes just the random things.
#=====================================================================================================================
require './src/internal/Configuration'

module GeneralTests
  MAX_NEW_ID_TRYS = 1_000_000 # 'nil' will run forever or untill it finds a match.
  #---------------------------------------------------------------------------------------------------------
  # Generate a bunch of new id's and check to see if any duplicates are found.
  def self.test_random_ids
    puts('Checking if able to reliably generate random ids.')
    trys = 0
    ids  = Set.new
    start_time = Time.now
    running = true
    dupes = 0
    mutex = Mutex.new
    while running
      new_id = nil
      threads = []
      # Max number of threads running at the same time is limited to the system environment, this requests 10 "jobs"
      10.times do |_t|
        thread = Thread.new do # each thread generates new ids
          mutex.synchronize do
            1000.times do |_i|
              trys += 1
              new_id = Configuration.generate_new_ref_id(as_string: true, clamp: false, micro: false, packed: false)
              # new_id = Configuration.generate_new_ref_id(as_string: true, packed: true).unpack('H*')[0]
              dupes += 1 unless ids.add?(new_id)
            end
            # running = false if dupes >= 10_000
          end
        end
        # collect the threads for joining together later
        threads.push(thread)
      end
      threads.each { |thread| thread.join } # wait here to sync all thread "job" work is done
      # trys = ids.size
      puts("Trys: (#{trys}) an id: [#{new_id}] Dupes: #{dupes}") if (trys % 10_000) == 0
      break if trys >= GeneralTests::MAX_NEW_ID_TRYS
    end
    puts("Test is over. Tried #{trys} times, took (#{(Time.now - start_time).round}) seconds." +
         "\n\t#{(dupes.to_f / trys.to_f * 100).round(4)}% duplicates.")
  end

  #---------------------------------------------------------------------------------------------------------
  # Test a typical basic outline for a net work package string of byte data.
  def self.test_hex_pacakge
    sample_package = "\xF6\x030y\x9By<\x00\x00\x00\x00\x00\x00\x00\x00Server shut down, goodbye 0 clients!"
    puts('Test bytes string to hex string.')
    # puts("(#{sample_package})") # can print raw bytes to terminal, leads to undesired results
    puts("(#{sample_package.inspect})")
    hex_string = sample_package.bytes.pack('c*').unpack1('H*')
    puts("(#{hex_string})")
    hex_unpacked = [hex_string].pack('H*')
    # puts("(#{hex_unpacked})") # can print raw bytes to terminal, leads to undesired results
    puts("(#{hex_unpacked.inspect})")
  end

  #---------------------------------------------------------------------------------------------------------
  # Figure out what the best way of packaging a Time object is.
  def self.test_time
    time_now = Time.new.getgm
    puts("Packing Time object: (#{time_now.to_f})")
    test_packing_time(time_now)
  end

  #---------------------------------------------------------------------------------------------------------
  # Different ways of packaging a Date time. Testing shows 'g' 'f' 'e' take up the least amount of bytes.
  def self.test_packing_time(time_object)
    %w[d D f F e E g G q Q].each do |flag|
      puts("Using mode: (#{flag})")
      packaged, unpacked = test_pack_mode(flag, time_object)
      puts("\packaged: (#{packaged.inspect}")
      puts("\tunpacked: (#{unpacked.inspect}")
      puts('')
    end
  end

  #---------------------------------------------------------------------------------------------------------
  def self.test_pack_mode(flag, use_time)
    case flag
    when 'q', 'Q'
      packaged = [use_time.to_f * 10_000_000].pack(flag)
      unpacked = packaged.unpack1(flag) / 10_000_000
    else # normal float
      packaged = [use_time.to_f].pack(flag)
      unpacked = packaged.unpack(flag)
    end
    [packaged, unpacked]
  end
end

puts('Running some tests:')

GeneralTests.test_time
GeneralTests.test_hex_pacakge
GeneralTests.test_random_ids

puts('Tests have finished.')
