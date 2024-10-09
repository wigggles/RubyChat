#=====================================================================================================================
# Contains the test groups that belong to the methods the * Magic Numbers * point to.
#=====================================================================================================================
class BenchTests
  #---------------------------------------------------------------------------------------------------------
  # Test indexer for Array v. Hash performance bench marks. Orders syntax job threw Benchmark for report.
  #---------------------------------------------------------------------------------------------------------
  def benches_hasharray(index, run_for = 1)
    case index
    when BT::HASH_VS_ARRAY::Array_ADD_DEL
      h = 'array add/del'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array.push(nr)
          @array.delete(nr - 1) if nr > 100
        end
      end
    when BT::HASH_VS_ARRAY::Hash_ADD_DEL
      h = 'hash add/del'
      s = Benchmark.measure do
        run_for.times do |nr|
          @hash[nr] = true
          @hash.delete(nr - 1) if nr > 100
        end
      end
    when BT::HASH_VS_ARRAY::Array_ADD
      h = 'add to array'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @array.push(false)
        end
      end
    when BT::HASH_VS_ARRAY::Hash_ADD
      h = 'add to hash'
      s = Benchmark.measure do
        run_for.times do |nr|
          @hash[nr] = true
        end
      end
    when BT::HASH_VS_ARRAY::Array_EACH
      h = "array.each[#{@array.size}]"
      s = Benchmark.measure do
        run_for.times do |_nr|
          @array.each { |x| }
        end
      end
    when BT::HASH_VS_ARRAY::Hash_EACH
      h = "hash.each[#{@hash.size}]"
      s = Benchmark.measure do
        run_for.times do |_nr|
          @hash.each { |k, _v| }
        end
      end
    when BT::HASH_VS_ARRAY::Hash_EACH_KEY
      h = "hash.each_key[#{@hash.size}]"
      s = Benchmark.measure do
        run_for.times do |_nr|
          @hash.each_key { |x| x }
        end
      end
    else
      s = "Unknown bench mark run for 'Array v. Hash' index(#{index})\n"
    end
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end

  #---------------------------------------------------------------------------------------------------------
  # Random number generation bench marks and status jobs.
  #---------------------------------------------------------------------------------------------------------
  def benches_random_number(index, run_for = 1)
    case index
    when BT::RND_NUMBER::FloatPoint
      h = 'float point'
      s = Benchmark.measure do
        run_for.times do |_nr|
          (0.0...Float::INFINITY).bsearch do |x|
            Math.log(x) >= 0
          end
        end
      end
    when BT::RND_NUMBER::Standard
      @array = []
      h = 'standard random'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @array.push(rand(10_000))
        end
      end
    when BT::RND_NUMBER::Ranged
      @array = []
      h = 'ranged random'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array.push(ranged_rand(nr, 10_000))
        end
      end
    when BT::RND_NUMBER::Find_Mean
      mean = 0
      h = '^ searched,'
      # why is this sometimes an even out come? Usually low < 5000 outcomes out of 10,000 trys
      run_for.times { |nr| mean += 1 if @array[nr] > 5000 }
      s = " numbers > 5000 (#{mean})\n"
    else
      s = "Unknown bench mark run for 'Random Number Gen' index(#{index})\n"
    end
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end

  #---------------------------------------------------------------------------------------------------------
  # Benchmark registry for Array related speed testing.
  #---------------------------------------------------------------------------------------------------------
  def benches_array(index, run_for)
    case index
    when BT::ARRAY_SPEED::LEVEL1_write
      @array = []
      h = 'Array 1 deep..'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array[nr] = nr
        end
      end
    when BT::ARRAY_SPEED::LEVEL1_read
      @array = []
      h = 'read 1 deep'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array[nr]
        end
      end
    when BT::ARRAY_SPEED::LEVEL2_write
      h = 'Array 2 deep..'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array[nr] = []
          @array[nr][nr] = nr
        end
      end
    when BT::ARRAY_SPEED::LEVEL2_read
      h = 'read 2 deep'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array[nr][nr]
        end
      end
    when BT::ARRAY_SPEED::LEVEL3_write
      h = 'Array 3 deep..'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array[nr] = []
          @array[nr][nr] = []
          @array[nr][nr][nr] = nr
        end
      end
    when BT::ARRAY_SPEED::LEVEL3_read
      h = 'read 3 deep'
      s = Benchmark.measure do
        run_for.times do |nr|
          @array[nr][nr][nr]
        end
      end
    when BT::ARRAY_SPEED::LOOP_FOR
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'for array'
      s = Benchmark.measure do
        run_for.times do |_nr|
          for value in @array; value ^ 2; end
        end
      end
    when BT::ARRAY_SPEED::LOOP_DO
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'do  array'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @array.each { |value|; value ^ 2 }
        end
      end
    when BT::ARRAY_SPEED::LOOP_INDEX
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'index array'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @array.length.times { |nr| @array[nr] ^ 2 }
        end
      end
    when BT::ARRAY_SPEED::LOOP_EACH
      range = 1..run_for # https://ruby-doc.org/core-2.4.0/Range.html
      @array = range.to_a
      h = 'array.each '
      s = Benchmark.measure do
        run_for.times do |_nr|
          @array.each { |value| value ^ 2 }
        end
      end
    else
      s = "Unknown bench mark run for 'Array functions' index(#{index})\n"
    end
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end

  #---------------------------------------------------------------------------------------------------------
  # Speed tests for input handling types.
  #---------------------------------------------------------------------------------------------------------
  def benches_input_speeds(index, run_for)
    case index
    when BT::INPUT_SPEED::UPDATE_LOOP
      h = 'scheme update loop'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @controls.update
        end
      end
    when BT::INPUT_SPEED::TRIGGER
      h = 'controls.trigger?'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @controls.trigger?(:backspace, true)
        end
      end
    when BT::INPUT_SPEED::HOLDING
      h = 'controls.holding?'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @controls.holding?(:backspace, true)
        end
      end
    when BT::INPUT_SPEED::SCHEME_TRIGGER
      h = 'is scheme.trigger?'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @controls.trigger?(:move_up)
        end
      end
    when BT::INPUT_SPEED::SCHEME_HOLD
      h = 'is scheme.holding?'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @controls.holding?(:move_up)
        end
      end
    when BT::INPUT_SPEED::GOSU_BUTTON_DOWN
      h = 'Gosu.button_down?'
      s = Benchmark.measure do
        run_for.times do |_nr|
          Gosu.button_down?(Gosu::KB_UP)
        end
      end
    when BT::INPUT_SPEED::HYBRID_MOVE
      h = 'input hybrid movement'
      s = Benchmark.measure do
        run_for.times do |_nr|
          @controls.input_move?
        end
      end
    else
      s = "Unknown bench mark run for 'Input Speed' index(#{index})\n"
    end
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end

  #---------------------------------------------------------------------------------------------------------
  # Speed tests between different call pointer types.
  #---------------------------------------------------------------------------------------------------------
  def benches_call_method(index, run_for)
    stress_class = StressAux_Class.new
    case index
    when BT::CALL_METHOD::MATH_LOCAL
      h = 'local'
      s = Benchmark.measure do
        run_for.times do |nr|
          _ = nr * nr # do work
        end
      end
    when BT::CALL_METHOD::MATH_MODULE
      h = 'module'
      s = Benchmark.measure do
        run_for.times do |nr|
          StressAux_Module.mathspeed(nr, nr)
        end
      end
    when BT::CALL_METHOD::MATH_CLASS
      class_called = StressAux_Class.new
      h = 'class'
      s = Benchmark.measure do
        run_for.times do |nr|
          class_called.mathspeed(nr, nr)
        end
      end
      class_called = nil
    when BT::CALL_METHOD::METHODS_LOCAL
      h = 'local'
      s = Benchmark.measure do
        run_for.times do |_nr|
          methods
        end
      end
    when BT::CALL_METHOD::METHODS_MODULE
      h = 'module'
      s = Benchmark.measure do
        run_for.times do |_nr|
          StressAux_Module.methods
        end
      end
    when BT::CALL_METHOD::METHODS_CLASS
      class_called = StressAux_Class.new
      h = 'class'
      s = Benchmark.measure do
        run_for.times do |_nr|
          class_called.methods
        end
      end
      class_called = nil
    when BT::CALL_METHOD::ARGUMENTS_CLASS_STRICT
      h = 'type- strict'
      s = Benchmark.measure do
        run_for.times do |_nr|
          stress_class.arguments_strict(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_CLASS_ARRAY
      h = 'type- array'
      s = Benchmark.measure do
        run_for.times do |_nr|
          stress_class.arguments_array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_CLASS_SYMBOL
      h = 'type- symbol'
      s = Benchmark.measure do
        run_for.times do |_nr|
          stress_class.arguments_symbol(
            one: 1, two: 2, three: 3, four: 4, five: 5,
            six: 6, seven: 7, eight: 8, nine: 9, ten: 10
          )
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_CLASS_VALUE
      h = 'type- hash'
      s = Benchmark.measure do
        run_for.times do |_nr|
          stress_class.arguments_value({
                                         one: 1, two: 2, three: 3, four: 4, five: 5,
                                         six: 6, seven: 7, eight: 8, nine: 9, ten: 10
                                       })
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_CLASS_HASH
      h = 'type- value'
      s = Benchmark.measure do
        run_for.times do |_nr|
          stress_class.arguments_hash(
            one: 1, two: 2, three: 3, four: 4, five: 5,
            six: 6, seven: 7, eight: 8, nine: 9, ten: 10
          )
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_MODULE_STRICT
      h = 'type- strict'
      s = Benchmark.measure do
        run_for.times do |_nr|
          StressAux_Module.arguments_strict(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_MODULE_ARRAY
      h = 'type- array'
      s = Benchmark.measure do
        run_for.times do |_nr|
          StressAux_Module.arguments_array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_MODULE_SYMBOL
      h = 'type- symbol'
      s = Benchmark.measure do
        run_for.times do |_nr|
          StressAux_Module.arguments_symbol(
            one: 1, two: 2, three: 3, four: 4, five: 5,
            six: 6, seven: 7, eight: 8, nine: 9, ten: 10
          )
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_MODULE_VALUE
      h = 'type- hash'
      s = Benchmark.measure do
        run_for.times do |_nr|
          StressAux_Module.arguments_value({
                                             one: 1, two: 2, three: 3, four: 4, five: 5,
                                             six: 6, seven: 7, eight: 8, nine: 9, ten: 10
                                           })
        end
      end
    when BT::CALL_METHOD::ARGUMENTS_MODULE_HASH
      h = 'type- value'
      s = Benchmark.measure do
        run_for.times do |_nr|
          StressAux_Module.arguments_hash(
            one: 1, two: 2, three: 3, four: 4, five: 5,
            six: 6, seven: 7, eight: 8, nine: 9, ten: 10
          )
        end
      end
    else
      s = "Unknown bench mark run for 'Class Calls' index(#{index})\n"
    end
    stress_class = nil
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end

  #---------------------------------------------------------------------------------------------------------
  # Speed tests between different variable access types.
  #---------------------------------------------------------------------------------------------------------
  def benches_variable_speeds(index, run_for)
    case index
    when BT::VARIABLE_SPEED::LOCAL_WRITE
      new_var = 1
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          new_var += 1
        end
      end
    when BT::VARIABLE_SPEED::LOCAL_READ
      copy_var = nil
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          copy_var = new_var
        end
      end
    when BT::VARIABLE_SPEED::INSTANCE_WRITE
      @instance_variable = 1
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          @instance_variable += 1
        end
      end
    when BT::VARIABLE_SPEED::INSTANCE_READ
      @copy_instance = nil
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          @copy_instance = @instance_variable
        end
      end
    when BT::VARIABLE_SPEED::CLASS_WRITE
      @@class_variable = 1
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          @@class_variable += 1
        end
      end
    when BT::VARIABLE_SPEED::CLASS_READ
      @@copy_class = nil
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          @@copy_class = @@class_variable
        end
      end
    when BT::VARIABLE_SPEED::GLOBAL_WRITE
      $global_variable = 1
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          $global_variable += 1
        end
      end
    when BT::VARIABLE_SPEED::GLOBAL_READ
      $copy_global = nil
      h = ''
      s = Benchmark.measure do
        run_for.times do |_nr|
          $copy_global = $global_variable
        end
      end
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
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end

  #---------------------------------------------------------------------------------------------------------
  # Speed comparison for numeric operations.
  #---------------------------------------------------------------------------------------------------------
  def benches_numeric(index, run_for)
    # offsets the clamping tests for keeping an int with in a low and high range. this
    # 'start' offsets to allow negatives to be used as well.
    start = run_for / 3
    # run test at index:
    case index
    when BT::NUMERIC::RANGE_CLAMP_if
      h = 'if Branch clamping'
      s = Benchmark.measure do
        run_for.times do |int|
          index = int - start
          if index < 0
            index = 0
          elsif index > start
            index = start
          end
        end
      end
    when BT::NUMERIC::RANGE_CLAMP_ternary
      h = 'Ternary Operator'
      s = Benchmark.measure do
        run_for.times do |int|
          index = int - start
          index = index > start ? start : index
          index = index < 0 ? 0 : index
        end
      end
    when BT::NUMERIC::RANGE_CLAMP_Ruby_clamp
      h = 'Ruby 2.4 clamp()'
      s = Benchmark.measure do
        run_for.times do |int|
          index = int - start
          index = index.clamp(0, start)
        end
      end
    when BT::NUMERIC::INCREMENT_add
      numeric_var = -500
      h = 'var += 1'
      s = Benchmark.measure do
        run_for.times do |_int|
          numeric_var += 1
        end
      end
    when BT::NUMERIC::INCREMENT_plus
      numeric_var = -500
      h = 'var = var + 1'
      s = Benchmark.measure do
        run_for.times do |_int|
          numeric_var += 1
        end
      end
    when BT::NUMERIC::DECREMENT_minus
      numeric_var = 500
      h = 'var -= 1'
      s = Benchmark.measure do
        run_for.times do |_int|
          numeric_var -= 1
        end
      end
    when BT::NUMERIC::DECREMENT_subtract
      numeric_var = 500
      h = 'var = var - 1'
      s = Benchmark.measure do
        run_for.times do |_int|
          numeric_var -= 1
        end
      end
    else
      s = "Unknown bench mark run for 'Numeric Tests' index(#{index})\n"
    end
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end

  #---------------------------------------------------------------------------------------------------------
  # Speed comparison for TCP network socket operations.
  #---------------------------------------------------------------------------------------------------------
  def benches_TCP_NETWORK(index, run_for)
    # Checks out aspects associated with TCPsession objects and network sockets.
    # run test at index:
    case index
    when BT::TCP_NETWORK::REF_ID_integer
      h = 'ref_id generation integer'
      s = Benchmark.measure do
        run_for.times do |_int|
          Configuration.generate_new_ref_id(as_string: false)
        end
      end
    when BT::TCP_NETWORK::REF_ID_string
      h = 'ref_id generation string'
      s = Benchmark.measure do
        run_for.times do |_int|
          Configuration.generate_new_ref_id(as_string: true)
        end
      end
    when BT::TCP_NETWORK::REF_ID_packed
      h = 'ref_id generation string packed'
      s = Benchmark.measure do
        run_for.times do |_int|
          Configuration.generate_new_ref_id(as_string: true, packed: true)
        end
      end
    when BT::TCP_NETWORK::PACKAGE_new
      h = 'TCPsession::Package creation'
      s = Benchmark.measure do
        run_for.times do |_int|
          TCPsession::Package.new(nil, '88888888')
        end
      end
    when BT::TCP_NETWORK::PACK_string_bytes
      loaded_package = TCPsession::Package.new(nil, '88888888')
      byte_string = nil
      h = 'TCPsession::Package string compression'
      s = Benchmark.measure do
        run_for.times do |_int|
          byte_string = loaded_package.pack_dt_string(
            'This is a test of the benchmarking TCPsession data package, this is only a test.'
          )
        end
      end
    when BT::TCP_NETWORK::UNPACK_bytes_string
      byte_string = "\xEA*%\xC7\xFB{<\x0088888888\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" +
                    'This is a test of the benchmarking TCPsession data package, this is only a test.'
      string_msg = ''
      h = 'TCPsession::Package string expansion'
      s = Benchmark.measure do
        run_for.times do |_int|
          package = TCPsession::Package.new(byte_string)
          string_msg = package.data.to_s
        end
      end
    else
      s = "Unknown bench mark run for 'TCP network tests' index(#{index})\n"
    end
    "#{h}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
end
