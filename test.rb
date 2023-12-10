#===============================================================================================================================
# !!!  Tests.rb |  Run a few tests.
#===============================================================================================================================
module Tests
  #---------------------------------------------------------------------------------------------------------
  # Figure out what the best way of packaging a Time object is.
  def self.test_time()
    time_now = Time.new().getgm()
    puts("Packing Time object: (#{time_now.to_f})")
    test_packing_time(time_now)
  end
  #---------------------------------------------------------------------------------------------------------
  def self.test_hex_pacakge()
    sample_package = "\xF6\x030y\x9By<\x00ServerHost\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00Server shut down, goodbye 0 clients!"
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
  def test_packing_time(time_object)
    %w(d D f F e E g G q Q).each { |flag|
      puts("Using mode: (#{flag})")
      packaged, unpacked = test_pack_mode(flag, time_object)
      puts("\packaged: (#{packaged.inspect}")
      puts("\tunpacked: (#{unpacked.inspect}")
      puts("")
    }
  end
  #---------------------------------------------------------------------------------------------------------
  def test_pack_mode(flag, use_time)
    case flag
    when 'q', 'Q'
      packaged = [use_time.to_f * 10000000].pack(flag)
      unpacked = packaged.unpack(flag) / 10000000
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

puts("Tests have finished.")
