#===============================================================================================================================
# !!! BenchTests.rb   | Contains the test groups associated with the test groups.
#-------------------------------------------------------------------------------------------------------------------------------
# The variable @test_length is for progress tracking to report group jobs finished.
#===============================================================================================================================
class BenchTests
  #---------------------------------------------------------------------------------------------------------
  #D: Compare the speed of using a Hash versus an Array.
  #---------------------------------------------------------------------------------------------------------
  def test_arrayhash_speed
    prep_new_test("Array v. Hash")
    @test_length = 7
    @array = []; @hash = {}
    BenchTests.showText(run_bench(BT::HASH_VS_ARRAY::Array_ADD_DEL, 1_000_000))
    BenchTests.showText(run_bench(BT::HASH_VS_ARRAY::Hash_ADD_DEL,  1_000_000))
    @array.clear; @hash.clear
    BenchTests.showText(run_bench(BT::HASH_VS_ARRAY::Array_ADD,     1_000_000))
    BenchTests.showText(run_bench(BT::HASH_VS_ARRAY::Hash_ADD,      1_000_000))
    # After creating an Array/Hash with the above pushes, check how long it takes to lookup an index in
    # something of that size. The length of the object is set by how many runs before the test ran. This
    # would be the "times" and on the @array and @hash variables. The times for the below tests is impacted
    # by the sizes of these two variables at test runtime.
    BenchTests.showText(run_bench(BT::HASH_VS_ARRAY::Array_EACH,           50))
    BenchTests.showText(run_bench(BT::HASH_VS_ARRAY::Hash_EACH,            50))
    BenchTests.showText(run_bench(BT::HASH_VS_ARRAY::Hash_EACH_KEY,        50))
    @array = []; @hash = {}
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Check the results of random out comes. Sometimes patterns appear and results in same number out come.
  #---------------------------------------------------------------------------------------------------------
  def test_random_number_gen
    prep_new_test("RND Numbers")
    @test_length = 5
    @array = []
    BenchTests.showText(run_bench(BT::RND_NUMBER::FloatPoint,    5000))
    BenchTests.showText(run_bench(BT::RND_NUMBER::Standard,    10_000))
    BenchTests.showText(run_bench(BT::RND_NUMBER::Find_Mean,   10_000)) # after generating, show mean
    BenchTests.showText(run_bench(BT::RND_NUMBER::Ranged,      10_000))
    BenchTests.showText(run_bench(BT::RND_NUMBER::Find_Mean,   10_000)) # after generating, show mean
    @array = []
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Get a benchmark of general Array usage cases for array syntax job performance compares.
  #---------------------------------------------------------------------------------------------------------
  def test_array_speeds
    prep_new_test("Array Speed")
    @test_length = 10
    @array = []
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LEVEL1_write, 10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LEVEL1_read,  10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LEVEL2_write, 10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LEVEL2_read,  10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LEVEL3_write, 10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LEVEL3_read , 10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LOOP_DO,      10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LOOP_FOR,     10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LOOP_INDEX,   10_000))
    BenchTests.showText(run_bench(BT::ARRAY_SPEED::LOOP_EACH,    10_000))
    @array = []
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Get a benchmark of different input checking style performances.
  #---------------------------------------------------------------------------------------------------------
  def test_input_speeds
    prep_new_test("Input Speed")
    @test_length = 7
    @array = []
    BenchTests.showText(run_bench(BT::INPUT_SPEED::UPDATE_LOOP,      10_000))
    BenchTests.showText(run_bench(BT::INPUT_SPEED::TRIGGER,          10_000))
    BenchTests.showText(run_bench(BT::INPUT_SPEED::HOLDING,          10_000))
    BenchTests.showText(run_bench(BT::INPUT_SPEED::SCHEME_TRIGGER,   10_000))
    BenchTests.showText(run_bench(BT::INPUT_SPEED::SCHEME_HOLD,      10_000))
    BenchTests.showText(run_bench(BT::INPUT_SPEED::GOSU_BUTTON_DOWN, 10_000))
    BenchTests.showText(run_bench(BT::INPUT_SPEED::HYBRID_MOVE,      10_000))
    @array = []
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Benches call method pointers for speed comparisons.
  #---------------------------------------------------------------------------------------------------------
  def test_class_calls
    prep_new_test("Class Calls")
    @test_length = 13
    BenchTests.showText("  Math:\n")
    BenchTests.showText(run_bench(BT::CALL_METHOD::MATH_local,     1_000_000))
    BenchTests.showText(run_bench(BT::CALL_METHOD::MATH_module,    1_000_000))
    BenchTests.showText(run_bench(BT::CALL_METHOD::MATH_class,     1_000_000))
    BenchTests.showText("\n  Methods:\n")
    BenchTests.showText(run_bench(BT::CALL_METHOD::METHODS_local,  1_000_000))
    BenchTests.showText(run_bench(BT::CALL_METHOD::METHODS_module, 1_000_000))
    BenchTests.showText(run_bench(BT::CALL_METHOD::METHODS_class,  1_000_000))
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Benches variable read/write access speed comparisons.
  #---------------------------------------------------------------------------------------------------------
  def test_variable_speeds
    prep_new_test("Variable Speeds")
    @test_length = 8
    BenchTests.showText("\n  Local:\n")
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::LOCAL_WRITE,    1_000_000))
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::LOCAL_READ,     1_000_000))
    BenchTests.showText("\n  Instance:\n")
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::INSTANCE_WRITE, 1_000_000))
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::INSTANCE_READ,  1_000_000))
    BenchTests.showText("\n  Class:\n")
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::CLASS_WRITE,    1_000_000))
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::CLASS_READ,     1_000_000))
    BenchTests.showText("\n  Global:\n")
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::GLOBAL_WRITE,   1_000_000))
    BenchTests.showText(run_bench(BT::VARIABLE_SPEED::GLOBAL_READ,    1_000_000))
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Run Benchmarks for Numeric functions for speed comparisons.
  #---------------------------------------------------------------------------------------------------------
  def test_numeric_functions
    prep_new_test("Numeric Operations")
    @test_length = 3
    BenchTests.showText("  Range Clamping:\n")
    BenchTests.showText(run_bench(BT::NUMERIC::RANGE_CLAMP_if,         1_000_000))
    BenchTests.showText(run_bench(BT::NUMERIC::RANGE_CLAMP_ternary,    1_000_000))
    BenchTests.showText(run_bench(BT::NUMERIC::RANGE_CLAMP_Ruby_clamp, 1_000_000))
    BenchTests.showText("\n   Inline Math:\n")
    BenchTests.showText(run_bench(BT::NUMERIC::INCREMENT_plus,         1_000_000))
    BenchTests.showText(run_bench(BT::NUMERIC::INCREMENT_add,          1_000_000))
    BenchTests.showText(run_bench(BT::NUMERIC::DECREMENT_minus,        1_000_000))
    BenchTests.showText(run_bench(BT::NUMERIC::DECREMENT_subtract,     1_000_000))
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Run Benchmarks for TCP network sockets for speed comparisons.
  #---------------------------------------------------------------------------------------------------------
  def test_TCP_NETWORK
    prep_new_test("TCP network Operations")
    @test_length = 2
    BenchTests.showText("  Package byte String data:\n")
    BenchTests.showText(run_bench(BT::TCP_NETWORK::REF_ID_integer,        500_000))
    BenchTests.showText(run_bench(BT::TCP_NETWORK::REF_ID_string,         500_000))
    BenchTests.showText(run_bench(BT::TCP_NETWORK::REF_ID_packed,         500_000))
    BenchTests.showText(run_bench(BT::TCP_NETWORK::PACKAGE_new,         1_000_000))
    BenchTests.showText(run_bench(BT::TCP_NETWORK::PACK_string_bytes,     100_000))
    BenchTests.showText(run_bench(BT::TCP_NETWORK::UNPACK_bytes_string,   100_000))
    BenchTests.display_footer()
    return true # if called using GUI.action() call_back
  end
end
