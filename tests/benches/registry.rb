#=====================================================================================================================
# Where all the * Magic Numbers * come to live together. Group_Names should have no spaces nor numbers in them.
#=====================================================================================================================
class BenchTests
  #---------------------------------------------------------------------------------------------------------
  # Ranges defined above for method/function sorting should match indexes to ranges bellow. * Magic Numbers *
  #---------------------------------------------------------------------------------------------------------
  module BT
    #--------------------------------------
    module HASH_VS_ARRAY; end
    HASH_VS_ARRAY::Group_Name = 'arrayHash'
    HASH_VS_ARRAY::TR = Range.new(1, 19)
    HASH_VS_ARRAY::Array_ADD_DEL         = 1
    HASH_VS_ARRAY::Hash_ADD_DEL          = 2
    HASH_VS_ARRAY::Array_ADD             = 3
    HASH_VS_ARRAY::Hash_ADD              = 4
    HASH_VS_ARRAY::Array_EACH            = 5
    HASH_VS_ARRAY::Hash_EACH             = 6
    HASH_VS_ARRAY::Hash_EACH_KEY         = 7
    #--------------------------------------
    module RND_NUMBER; end
    RND_NUMBER::Group_Name = 'randomNumbers'
    RND_NUMBER::TR = Range.new(20, 39)
    RND_NUMBER::Standard                 = 21
    RND_NUMBER::Ranged                   = 22
    RND_NUMBER::FloatPoint               = 23
    RND_NUMBER::Find_Mean                = 24 # <- test uses benchmark ran above it.
    #--------------------------------------
    module ARRAY_SPEED; end
    ARRAY_SPEED::Group_Name = 'arraySpeed'
    ARRAY_SPEED::TR = Range.new(40, 69)
    ARRAY_SPEED::LEVEL1_write            = 41
    ARRAY_SPEED::LEVEL1_read             = 42
    ARRAY_SPEED::LEVEL2_write            = 43
    ARRAY_SPEED::LEVEL2_read             = 44
    ARRAY_SPEED::LEVEL3_write            = 45
    ARRAY_SPEED::LEVEL3_read             = 46
    ARRAY_SPEED::LOOP_FOR                = 47
    ARRAY_SPEED::LOOP_DO                 = 48
    ARRAY_SPEED::LOOP_INDEX              = 49
    ARRAY_SPEED::LOOP_EACH               = 50
    #--------------------------------------
    module INPUT_SPEED; end
    INPUT_SPEED::Group_Name = 'inputSpeed'
    INPUT_SPEED::TR = Range.new(70, 89)
    INPUT_SPEED::UPDATE_LOOP             = 71
    INPUT_SPEED::TRIGGER                 = 72
    INPUT_SPEED::HOLDING                 = 73
    INPUT_SPEED::SCHEME_TRIGGER          = 74
    INPUT_SPEED::SCHEME_HOLD             = 75
    INPUT_SPEED::GOSU_BUTTON_DOWN        = 76
    INPUT_SPEED::HYBRID_MOVE             = 77
    #--------------------------------------
    module CALL_METHOD; end
    CALL_METHOD::Group_Name = 'classCalls'
    CALL_METHOD::TR = Range.new(100, 119)
    CALL_METHOD::MATH_LOCAL              = 101
    CALL_METHOD::MATH_MODULE             = 102
    CALL_METHOD::MATH_CLASS              = 103
    CALL_METHOD::METHODS_LOCAL           = 104
    CALL_METHOD::METHODS_MODULE          = 105
    CALL_METHOD::METHODS_CLASS           = 106
    CALL_METHOD::ARGUMENTS_CLASS_STRICT  = 107
    CALL_METHOD::ARGUMENTS_CLASS_ARRAY   = 108
    CALL_METHOD::ARGUMENTS_CLASS_SYMBOL  = 109
    CALL_METHOD::ARGUMENTS_CLASS_VALUE   = 110
    CALL_METHOD::ARGUMENTS_CLASS_HASH    = 111
    CALL_METHOD::ARGUMENTS_MODULE_STRICT = 112
    CALL_METHOD::ARGUMENTS_MODULE_ARRAY  = 113
    CALL_METHOD::ARGUMENTS_MODULE_SYMBOL = 114
    CALL_METHOD::ARGUMENTS_MODULE_VALUE  = 115
    CALL_METHOD::ARGUMENTS_MODULE_HASH   = 116
    #--------------------------------------
    module VARIABLE_SPEED; end
    VARIABLE_SPEED::Group_Name = 'variableSpeeds'
    VARIABLE_SPEED::TR = Range.new(120, 139)
    VARIABLE_SPEED::LOCAL_WRITE          = 121
    VARIABLE_SPEED::LOCAL_READ           = 122
    VARIABLE_SPEED::INSTANCE_WRITE       = 123
    VARIABLE_SPEED::INSTANCE_READ        = 124
    VARIABLE_SPEED::CLASS_WRITE          = 125
    VARIABLE_SPEED::CLASS_READ           = 126
    VARIABLE_SPEED::GLOBAL_WRITE         = 127
    VARIABLE_SPEED::GLOBAL_READ          = 128
    #--------------------------------------
    module NUMERIC; end
    NUMERIC::Group_Name = 'numericFunctions'
    NUMERIC::TR = Range.new(140, 169)
    NUMERIC::RANGE_CLAMP_if              = 141
    NUMERIC::RANGE_CLAMP_ternary         = 142
    NUMERIC::RANGE_CLAMP_Ruby_clamp      = 143
    NUMERIC::INCREMENT_add               = 144
    NUMERIC::INCREMENT_plus              = 145
    NUMERIC::DECREMENT_minus             = 146
    NUMERIC::DECREMENT_subtract          = 147
    #--------------------------------------
    module TCP_NETWORK; end
    TCP_NETWORK::Group_Name = 'TCP_NETWORK'
    TCP_NETWORK::TR = Range.new(200, 229)
    TCP_NETWORK::REF_ID_integer          = 201
    TCP_NETWORK::REF_ID_string           = 202
    TCP_NETWORK::REF_ID_packed           = 203
    TCP_NETWORK::PACKAGE_new             = 211
    TCP_NETWORK::PACK_string_bytes       = 212
    TCP_NETWORK::UNPACK_bytes_string     = 213
    #--------------------------------------
  end

  #---------------------------------------------------------------------------------------------------------
  # Called to a registry of bench mark runs ready to test. Dispatches the run group and current index ID.
  # This is done to allow if required a Gosu.tick intermittent call if a group of bench marks takes a long time.
  # Providing a prevention outlet to 'hang' issues for long benches with results wished to be shown in GUI.
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
    "#{index}\t(#{run_for})\t#{s}" # benchmark adds \n return from s
  end
end
