#===============================================================================================================================
# Where all the * Magic Numbers * come to live together. Group_Names should have no spaces nor numbers in them.
#===============================================================================================================================
class BenchTests
  #---------------------------------------------------------------------------------------------------------
  # Ranges defined above for method/function sorting should match indexes to ranges bellow. * Magic Numbers *
  #---------------------------------------------------------------------------------------------------------
  module BT
    #--------------------------------------
    module HASH_VS_ARRAY; end
    HASH_VS_ARRAY::Group_Name = 'arrayHash'
    HASH_VS_ARRAY::TR  = Range.new( 1, 19)
    HASH_VS_ARRAY::Array_ADD_DEL     = 1
    HASH_VS_ARRAY::Hash_ADD_DEL      = 2
    HASH_VS_ARRAY::Array_ADD         = 3
    HASH_VS_ARRAY::Hash_ADD          = 4
    HASH_VS_ARRAY::Array_EACH        = 5
    HASH_VS_ARRAY::Hash_EACH         = 6
    HASH_VS_ARRAY::Hash_EACH_KEY     = 7
    #--------------------------------------
    module RND_NUMBER; end
    RND_NUMBER::Group_Name = 'randomNumbers'
    RND_NUMBER::TR     = Range.new( 20, 39)
    RND_NUMBER::Standard             = 21
    RND_NUMBER::Ranged               = 22
    RND_NUMBER::FloatPoint           = 23
    RND_NUMBER::Find_Mean            = 24  
    # ^ last one is more of a follow up tool to a benchmark ran before it.
    #--------------------------------------
    module ARRAY_SPEED; end
    ARRAY_SPEED::Group_Name = 'arraySpeed'
    ARRAY_SPEED::TR   = Range.new( 40, 59)
    ARRAY_SPEED::LEVEL1_write        = 41
    ARRAY_SPEED::LEVEL1_read         = 42
    ARRAY_SPEED::LEVEL2_write        = 43
    ARRAY_SPEED::LEVEL2_read         = 44
    ARRAY_SPEED::LEVEL3_write        = 45
    ARRAY_SPEED::LEVEL3_read         = 46
    ARRAY_SPEED::LOOP_FOR            = 47
    ARRAY_SPEED::LOOP_DO             = 48
    ARRAY_SPEED::LOOP_INDEX          = 49
    ARRAY_SPEED::LOOP_EACH           = 50
    #--------------------------------------
    module INPUT_SPEED; end
    INPUT_SPEED::Group_Name = 'inputSpeed'
    INPUT_SPEED::TR   = Range.new( 60, 79)
    INPUT_SPEED::UPDATE_LOOP      = 61
    INPUT_SPEED::TRIGGER          = 62
    INPUT_SPEED::HOLDING          = 63
    INPUT_SPEED::SCHEME_TRIGGER   = 64
    INPUT_SPEED::SCHEME_HOLD      = 65
    INPUT_SPEED::GOSU_BUTTON_DOWN = 66
    INPUT_SPEED::HYBRID_MOVE      = 67
    #--------------------------------------
    module CALL_METHOD; end
    CALL_METHOD::Group_Name = 'classCalls'
    CALL_METHOD::TR    = Range.new(100, 109)
    CALL_METHOD::MATH_local          = 101
    CALL_METHOD::MATH_module         = 102
    CALL_METHOD::MATH_class          = 103
    CALL_METHOD::METHODS_local       = 104
    CALL_METHOD::METHODS_module      = 105
    CALL_METHOD::METHODS_class       = 106
    #--------------------------------------
    module VARIABLE_SPEED;end
    VARIABLE_SPEED::Group_Name = 'variableSpeeds'
    VARIABLE_SPEED::TR    = Range.new(110, 119)
    VARIABLE_SPEED::LOCAL_WRITE          = 111
    VARIABLE_SPEED::LOCAL_READ           = 112
    VARIABLE_SPEED::INSTANCE_WRITE       = 113
    VARIABLE_SPEED::INSTANCE_READ        = 114
    VARIABLE_SPEED::CLASS_WRITE          = 115
    VARIABLE_SPEED::CLASS_READ           = 116
    VARIABLE_SPEED::GLOBAL_WRITE         = 117
    VARIABLE_SPEED::GLOBAL_READ          = 118
    #--------------------------------------
    module NUMERIC; end
    NUMERIC::Group_Name = 'numericFunctions'
    NUMERIC::TR        = Range.new(120, 139)
    NUMERIC::RANGE_CLAMP_if          = 121
    NUMERIC::RANGE_CLAMP_ternary     = 122
    NUMERIC::RANGE_CLAMP_Ruby_clamp  = 123
    NUMERIC::INCREMENT_add           = 124
    NUMERIC::INCREMENT_plus          = 125
    NUMERIC::DECREMENT_minus         = 126
    NUMERIC::DECREMENT_subtract      = 127
    #--------------------------------------
    module TCP_NETWORK; end
    TCP_NETWORK::Group_Name = 'TCP_NETWORK'
    TCP_NETWORK::TR     = Range.new(200, 229)
    TCP_NETWORK::REF_ID_integer       = 201
    TCP_NETWORK::REF_ID_string        = 202
    TCP_NETWORK::REF_ID_packed        = 203
    TCP_NETWORK::PACKAGE_new          = 211
    TCP_NETWORK::PACK_string_bytes    = 212
    TCP_NETWORK::UNPACK_bytes_string  = 213
    #--------------------------------------
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called to a registry of bench mark runs ready to test. Dispatches the run group and current index ID.
  #D: This is done to allow if required a Gosu.tick intermittent call if a group of bench marks takes a long time.
  #D: Providing a prevention outlet to 'hang' issues for long benches with results wished to be shown in GUI.
  #---------------------------------------------------------------------------------------------------------
  def run_bench(index, run_for = 0)
    @test_index += 1 # if keeping track..
    case index
    when BT::HASH_VS_ARRAY::TR  then return benches_hasharray(index, run_for)
    when BT::RND_NUMBER::TR     then return benches_random_number(index, run_for)
    when BT::ARRAY_SPEED::TR    then return benches_array(index, run_for)
    when BT::INPUT_SPEED::TR    then return benches_input_speeds(index, run_for)
    when BT::CALL_METHOD::TR    then return benches_call_method(index, run_for)
    when BT::VARIABLE_SPEED::TR then return benches_variable_speeds(index, run_for)
    when BT::NUMERIC::TR        then return benches_numeric(index, run_for)
    when BT::TCP_NETWORK::TR    then return benches_TCP_NETWORK(index, run_for)
    else
      s = "Unknown bench mark run for index(#{index})\n"
    end
    return "#{index}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
end
