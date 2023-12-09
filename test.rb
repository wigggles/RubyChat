# figure out what the best way of packaging a Time object is.

TEST_MODES = %w(d D f F e E g G q Q)

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

def test_packing_time(time_object)
  TEST_MODES.each { |flag|
    puts("Using mode: (#{flag})")
    packaged, unpacked = test_pack_mode(flag, time_object)
    puts("\packaged: (#{packaged.inspect}")
    puts("\tunpacked: (#{unpacked.inspect}")
    puts("")
  }
end

time_now = Time.new().getgm()
puts("Packing Time object: (#{time_now.to_f})")
test_packing_time(time_now)
