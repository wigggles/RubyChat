#===============================================================================================================================
# Contains the test groups that belong to the methods the * Magic Numbers * point to.
#===============================================================================================================================
class BenchTests
  #---------------------------------------------------------------------------------------------------------
  #D: Test indexer for Array v. Hash performance bench marks. Orders syntax job threw Benchmark for report.
  #---------------------------------------------------------------------------------------------------------
  def benches_hasharray(index, run_for = 1)
    case index
    when BT::HASH_VS_ARRAY::Array_ADD_DEL
      h = 'array add/del'; s = Benchmark.measure{run_for.times { |nr|
        @array.push(nr); @array.delete(nr-1) if nr > 100
      }}
    when BT::HASH_VS_ARRAY::Hash_ADD_DEL
      h = 'hash add/del'; s = Benchmark.measure{run_for.times { |nr|
        @hash[nr] = true; @hash.delete(nr-1) if nr > 100
      }}
    when BT::HASH_VS_ARRAY::Array_ADD
      h = 'add to array'; s = Benchmark.measure{run_for.times { |nr|
        @array.push(false)
      }}
    when BT::HASH_VS_ARRAY::Hash_ADD
      h = 'add to hash'; s = Benchmark.measure{run_for.times { |nr|
        @hash[nr] = true
      }}
    when BT::HASH_VS_ARRAY::Array_EACH
      h = "array.each[#{@array.size}]"; s = Benchmark.measure{run_for.times { |nr|
        @array.each { |x| x }
      }}
    when BT::HASH_VS_ARRAY::Hash_EACH
      h = "hash.each[#{@hash.size}]"; s = Benchmark.measure{run_for.times { |nr|
        @hash.each { |k,v| k }
      }}
    when BT::HASH_VS_ARRAY::Hash_EACH_KEY
      h = "hash.each_key[#{@hash.size}]"; s = Benchmark.measure{run_for.times { |nr|
        @hash.each_key { |x| x }
      }}
    else
      s = "Unknown bench mark run for 'Array v. Hash' index(#{index})\n"
    end
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Random number generation bench marks and status jobs.
  #---------------------------------------------------------------------------------------------------------
  def benches_random_number(index, run_for = 1)
    case index
    when BT::RND_NUMBER::FloatPoint
      h = 'float point'; s = Benchmark.measure{run_for.times { |nr|
        (0.0...Float::INFINITY).bsearch { |x| 
          i = Math.log(x) >= 0
        }
      }}
    when BT::RND_NUMBER::Standard
      @array = []
      h = 'standard random'; s = Benchmark.measure{run_for.times { |nr|
        @array.push( rand(10_000) )
      }}
    when BT::RND_NUMBER::Ranged
      @array = []
      h = 'ranged random'; s = Benchmark.measure{run_for.times { |nr|
        @array.push( ranged_rand(nr, 10_000) )
      }}
    when BT::RND_NUMBER::Find_Mean
      mean = 0; h = "^ searched,"
      # why is this sometimes an even out come? Usually low < 5000 outcomes out of 10,000 trys
      run_for.times { |nr| mean += 1 if @array[nr] > 5000 }
      s = " numbers > 5000 (#{mean})\n"
    else
      s = "Unknown bench mark run for 'Random Number Gen' index(#{index})\n"
    end
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Benchmark registry for Array related speed testing.
  #---------------------------------------------------------------------------------------------------------
  def benches_array(index, run_for)
    case index
    when BT::ARRAY_SPEED::LEVEL1_write
      @array = []
      h = 'Array 1 deep..'; s = Benchmark.measure{run_for.times { |nr|
        @array[nr] = nr
      }}
    when BT::ARRAY_SPEED::LEVEL1_read
      @array = []
      h = 'read 1 deep'; s = Benchmark.measure{run_for.times { |nr|
        value = @array[nr]
      }}
    when BT::ARRAY_SPEED::LEVEL2_write
      h = 'Array 2 deep..'; s = Benchmark.measure{run_for.times { |nr|
        @array[nr] = []
        @array[nr][nr] = nr
      }}
    when BT::ARRAY_SPEED::LEVEL2_read
      h = 'read 2 deep'; s = Benchmark.measure{run_for.times { |nr|
        value = @array[nr][nr]
      }}
    when BT::ARRAY_SPEED::LEVEL3_write
      h = 'Array 3 deep..'; s = Benchmark.measure{run_for.times { |nr|
        @array[nr] = []
        @array[nr][nr] = []
        @array[nr][nr][nr] = nr
      }}
    when BT::ARRAY_SPEED::LEVEL3_read
      h = 'read 3 deep'; s = Benchmark.measure{run_for.times { |nr|
        value = @array[nr][nr][nr]
      }}
    when BT::ARRAY_SPEED::LOOP_FOR
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'for array'; s = Benchmark.measure{run_for.times { |nr|
        for value in @array; value ^ 2; end
      }}
    when BT::ARRAY_SPEED::LOOP_DO
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'do  array'; s = Benchmark.measure{run_for.times { |nr|
        @array.each do |value|; value ^ 2; end
      }}
    when BT::ARRAY_SPEED::LOOP_INDEX
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'index array'; s = Benchmark.measure{run_for.times { |nr|
        @array.length.times {|nr| @array[nr] ^ 2 }
      }}
    when BT::ARRAY_SPEED::LOOP_EACH
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'array.each '; s = Benchmark.measure{run_for.times { |nr|
        @array.each {|value| value ^ 2 }
      }}
    else
      s = "Unknown bench mark run for 'Array functions' index(#{index})\n"
    end
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Speed tests for input handling types.
  #---------------------------------------------------------------------------------------------------------
  def benches_input_speeds(index, run_for)
    $controls = InputControls.new() if $controls.nil?
    case index
    when BT::INPUT_SPEED::UPDATE_LOOP
      h = 'scheme update loop'; s = Benchmark.measure{run_for.times { |nr|
        $controls.update
      }}
    when BT::INPUT_SPEED::TRIGGER
      h = '$controls.trigger?'; s = Benchmark.measure{run_for.times { |nr|
        $controls.trigger?(:backspace, true)
      }}
    when BT::INPUT_SPEED::HOLDING
      h = '$controls.holding?'; s = Benchmark.measure{run_for.times { |nr|
        $controls.holding?(:backspace, true)
      }}
    when BT::INPUT_SPEED::SCHEME_TRIGGER
      h = 'is scheme.trigger?'; s = Benchmark.measure{run_for.times { |nr|
        $controls.trigger?(:move_up)
      }}
    when BT::INPUT_SPEED::SCHEME_HOLD
      h = 'is scheme.holding?'; s = Benchmark.measure{run_for.times { |nr|
        $controls.holding?(:move_up)
      }}
    when BT::INPUT_SPEED::GOSU_BUTTON_DOWN
      h = 'Gosu.button_down?'; s = Benchmark.measure{run_for.times { |nr|
        Gosu.button_down?(Gosu::KB_UP)
      }}
    when BT::INPUT_SPEED::HYBRID_MOVE
      h = 'input hybrid movement'; s = Benchmark.measure{run_for.times { |nr|
        $controls.input_move?
      }}
    else
      s = "Unknown bench mark run for 'Input Speed' index(#{index})\n"
    end
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Speed tests between different call pointer types.
  #---------------------------------------------------------------------------------------------------------
  def benches_call_method(index, run_for)
    case index
    when BT::CALL_METHOD::MATH_local
      h = 'local'; s = Benchmark.measure{run_for.times { |nr|
        int = nr ^ nr
      }}
    when BT::CALL_METHOD::MATH_module
      h = 'module'; s = Benchmark.measure{run_for.times { |nr|
        int = StressAux_Module.mathspeed(nr, nr)
      }}
    when BT::CALL_METHOD::MATH_class
      class_called = StressAux_Class.new()
      h = 'class'; s = Benchmark.measure{run_for.times { |nr|
        int = class_called.mathspeed(nr, nr)
      }}
      class_called = nil
    when BT::CALL_METHOD::METHODS_local
      h = 'local'; s = Benchmark.measure{run_for.times { |nr|
        methods
      }}
    when BT::CALL_METHOD::METHODS_module
      h = 'module'; s = Benchmark.measure{run_for.times { |nr|
        StressAux_Module.methods
      }}
    when BT::CALL_METHOD::METHODS_class
      class_called = StressAux_Class.new()
      h = 'class'; s = Benchmark.measure{run_for.times { |nr|
        class_called.methods
      }}
      class_called = nil
    else
      s = "Unknown bench mark run for 'Array v. Hash' index(#{index})\n"
    end
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Speed tests between different variable access types.
  #---------------------------------------------------------------------------------------------------------
  def benches_variable_speeds(index, run_for)
    case index
    when BT::VARIABLE_SPEED::LOCAL_WRITE
      new_var = 1
      h = ''; s = Benchmark.measure{run_for.times { |nr|
        new_var += 1
      }}
    when BT::VARIABLE_SPEED::LOCAL_READ
      copy_var = nil
      h = ''; s = Benchmark.measure{run_for.times { |nr|
      copy_var = new_var
      }}
    when BT::VARIABLE_SPEED::INSTANCE_WRITE
      @instance_variable = 1
      h = ''; s = Benchmark.measure{run_for.times { |nr|
       @instance_variable += 1
      }}
    when BT::VARIABLE_SPEED::INSTANCE_READ
      @copy_instance = nil
      h = ''; s = Benchmark.measure{run_for.times { |nr|
        @copy_instance = @instance_variable
      }}
    when BT::VARIABLE_SPEED::CLASS_WRITE
      @@class_variable = 1
      h = ''; s = Benchmark.measure{run_for.times { |nr|
        @@class_variable += 1
      }}
    when BT::VARIABLE_SPEED::CLASS_READ
      @@copy_class = nil
      h = ''; s = Benchmark.measure{run_for.times { |nr|
        @@copy_class = @@class_variable
      }}
    when BT::VARIABLE_SPEED::GLOBAL_WRITE
      $global_variable = 1
      h = ''; s = Benchmark.measure{run_for.times { |nr|
        $global_variable += 1
      }}
    when BT::VARIABLE_SPEED::GLOBAL_READ
      $copy_global = nil
      h = ''; s = Benchmark.measure{run_for.times { |nr|
      $copy_global = $global_variable
      }}
    else
      s = "Unknown bench mark run for 'Variable Speeds' index(#{index})\n"
    end
    # help GC with test variable cleanup
    @instance_variable = nil
    @copy_instance = nil
    @@class_variable = nil
    @@copy_class = nil
    $global_variable = nil
    $copy_global = nil
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Speed comparison for numeric operations.
  #---------------------------------------------------------------------------------------------------------
  def benches_numeric(index, run_for)
    # offsets the clamping tests for keeping an int with in a low and high range. this
    # 'start' offsets to allow negatives to be used as well.
    start = run_for / 3
    # run test at index:
    case index
    when BT::NUMERIC::RANGE_CLAMP_if
      h = 'if Branch clamping'; s = Benchmark.measure{run_for.times { |int|
        index = int - start
        if index < 0
          index = 0
        elsif index > start
          index = start
        end
      }}
    when BT::NUMERIC::RANGE_CLAMP_ternary
      h = 'Ternary Operator'; s = Benchmark.measure{run_for.times { |int|
        index = int - start
        index = index > start ? start : index
        index = index < 0 ? 0 : index
      }}
    when BT::NUMERIC::RANGE_CLAMP_Ruby_clamp
      h = 'Ruby 2.4 clamp()'; s = Benchmark.measure{run_for.times { |int|
        index = int - start
        index = index.clamp(0, start)
      }}
    when BT::NUMERIC::INCREMENT_add
      numeric_var = -500
      h = 'var += 1'; s = Benchmark.measure{run_for.times { |int|
        numeric_var += 1
      }}
    when BT::NUMERIC::INCREMENT_plus
      numeric_var = -500
      h = 'var = var + 1'; s = Benchmark.measure{run_for.times { |int|
        numeric_var = numeric_var + 1
      }}
    when BT::NUMERIC::DECREMENT_minus
      numeric_var = 500
      h = 'var -= 1'; s = Benchmark.measure{run_for.times { |int|
        numeric_var -= 1
      }}
    when BT::NUMERIC::DECREMENT_subtract
      numeric_var = 500
      h = 'var = var - 1'; s = Benchmark.measure{run_for.times { |int|
        numeric_var = numeric_var - 1
      }}
    else
      s = "Unknown bench mark run for 'Numeric Tests' index(#{index})\n"
    end
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Speed comparison for TCP network socket operations.
  #---------------------------------------------------------------------------------------------------------
  def benches_TCP_NETWORK(index, run_for)
    # Checks out aspects associated with TCPsession objects and network sockets.
    # run test at index:
    case index
    when BT::TCP_NETWORK::REF_ID_integer
      h = 'ref_id generation integer'; s = Benchmark.measure{run_for.times { |int|
        new_id = Configuration.generate_new_ref_id(as_string: false)
      }}
    when BT::TCP_NETWORK::REF_ID_string
      h = 'ref_id generation string'; s = Benchmark.measure{run_for.times { |int|
        new_id = Configuration.generate_new_ref_id(as_string: true)
      }}
    when BT::TCP_NETWORK::REF_ID_packed
      h = 'ref_id generation string packed'; s = Benchmark.measure{run_for.times { |int|
        new_id = Configuration.generate_new_ref_id(as_string: true, packed: true)
      }}
    when BT::TCP_NETWORK::PACKAGE_new
      h = 'TCPsession::Package creation'; s = Benchmark.measure{run_for.times { |int|
        create_package = TCPsession::Package.new(nil, '88888888')
      }}
    when BT::TCP_NETWORK::PACK_string_bytes
      loaded_package = TCPsession::Package.new(nil, '88888888')
      byte_string = nil
      h = 'TCPsession::Package string compression'; s = Benchmark.measure{run_for.times { |int|
        byte_string = loaded_package.pack_dt_string(
          "This is a test of the benchmarking TCPsession data package, this is only a test."
        )
      }}
    when BT::TCP_NETWORK::UNPACK_bytes_string
      byte_string = "\xEA*%\xC7\xFB{<\x0088888888\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00This is a test of the benchmarking TCPsession data package, this is only a test."
      string_msg = ""
      h = 'TCPsession::Package string expansion'; s = Benchmark.measure{run_for.times { |int|
        package = TCPsession::Package.new(byte_string)
        string_msg = package.data.to_s()
      }}
    else
      s = "Unknown bench mark run for 'TCP network tests' index(#{index})\n"
    end
    return "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
end
