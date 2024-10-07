#!/usr/bin/env ruby
#===============================================================================================================================
# Synopsis:
#   In Terminal or Command Prompt use the following while 'cd' with in the containing directory of this source file.
#     ruby benchmark.rb --run <test_group_name>
#
#   You can also run individual tests by providing their id and an optional times argument. if no --times, it just does 10,000
#     ruby benchmark.rb --run <test_id> --times <amount>
#
# Tests are registered by an id with in the Benchmark suite manager. Test names for these groups are:
#    quick_bench        - Run direct test, check function 'BenchTests.quick_test' for more information.
#    arrayHash          - Test Array vs Hash storage calls and function for speed comparison.
#    arraySpeed         - Check the speed of Array tables and function calling.
#    inputSpeed         - Compare the speed of the various input checking styles.
#    classCalls         - Test call method return time across a basic Module and Class.
#    variableSpeeds     - Compare the speed of read/write access for variable types.
#    randomNumbers      - Check speed in returning a reliable random number.
#    numericFunctions   - Compare the speed of Math equating.
#    TCP_NETWORK        - Checkout the speeds for aspects of TCP socketing.
#
#  The most current description and items in the Benchmark suite will always be found in the registry of * Magic Numbers *
#
# To run every test simply use:
#     ruby benchmark.rb
#
# * Note, this may seem excessive, but this organizes the testing in a manor that makes batches configurable and allow for
# specific targets however those may change during the usage of fetching commonly used bench tests.
#
#===============================================================================================================================
require 'benchmark' # https://ruby-doc.org/stdlib-1.9.3/libdoc/benchmark/rdoc/Benchmark.html
# https://blog.appsignal.com/2018/02/27/benchmarking-ruby-code.html
#===============================================================================================================================
require 'gosu'
require '../src/internal/Configuration.rb'
require '../src/internal/InputControls.rb'

#==============================================================================================================================
# Source classes used in the testing should be loaded/required here.

require '../src/network/ClientPool.rb'
require '../src/network/TCP/session-Package.rb'
require '../src/network/TCP/session.rb'
require '../src/network/TCP/server.rb'
require '../src/network/TCP/client.rb'

#===============================================================================================================================
# To assist in organization, the BenchTests object has been divided across multiple files. 
require './benches/registry.rb'      # Magic number container for defining tests.
require './benches/test_groups.rb'   # Each test group, for running whole tests.
require './benches/branches.rb'      # Where the tests are outlined.

class BenchTests
  #---------------------------------------------------------------------------------------------------------
  #D: Generally blank but an availabel spot for benchmarking code snippets quickly. 
  #---------------------------------------------------------------------------------------------------------
  def self.quick_bench()
    BenchTests.display_header("Quick Bench")
    #-----------------------------
    # This is a rough layout for a bench mark test, 
    # feel free to copy the formatting.
    h = 'Quick Bench'; run_for = 10_000
    temp = 0
    # reports times as string "user system total ( real)\n"
    s = Benchmark.measure { 
      run_for.times { |nr|
      # Put the code your looking to test with in line dividers:
      #-----------------------------
      # Code snippet to test a speed of:

        temp += nr # adding numbers for example..

      # can be multiple lines, calls n such.
      #-----------------------------
    }}
    # build the return display format for proper window and console report style
    BenchTests.showText("#{h}\t(#{run_for})\t#{s}")
    #-----------------------------
    BenchTests.display_footer()
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Create klass object.
  #---------------------------------------------------------------------------------------------------------
  def initialize()
    $STRESS_TESTING = true # used when importing classes to set additional object internals if needed
    @array = []
    @hash = {}
    @test_index  = 0
    @test_length = 1
    puts "\n=========================================================================="
    print("Generally speaking, any \"Real\" number above 0.25 (a 1/4 second) is lag.\n")
    puts "I.E. an FPS of 60 * 0.25 is 15 frames of lag, or an FPS of 45"
    puts "PAL screens at 24 FPS, most games of 2D type are 30 FPS."
    puts "=========================================================================="
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Run a selected bench test suite. The names of these groups are found in the registry of * Magic Numbers *
  #---------------------------------------------------------------------------------------------------------
  def run(group)
    case group
    when BT::HASH_VS_ARRAY::Group_Name  then test_arrayhash_speed()
    when BT::RND_NUMBER::Group_Name     then test_array_speeds()
    when BT::ARRAY_SPEED::Group_Name    then test_class_calls()
    when BT::VARIABLE_SPEED::Group_Name then test_variable_speeds()
    when BT::INPUT_SPEED::Group_Name    then test_input_speeds()
    when BT::CALL_METHOD::Group_Name    then test_random_number_gen()
    when BT::NUMERIC::Group_Name        then test_numeric_functions()
    when BT::TCP_NETWORK::Group_Name    then test_TCP_NETWORK()
    when 'quick_bench' then quick_bench()
    else
      puts "There is not Benchmark test group by that tag identifier: #{group}"
    end
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Run all benches availabel.
  #---------------------------------------------------------------------------------------------------------
  def run_all()
    test_arrayhash_speed()
    test_array_speeds()
    test_class_calls()
    test_variable_speeds()
    test_input_speeds()
    test_random_number_gen()
    test_numeric_functions()
    test_TCP_NETWORK()
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Resets for fresh content.
  #---------------------------------------------------------------------------------------------------------
  def prep_new_test(h = '')
    @display_text = [] # clears all showText() strings if using a GUI
    @test_index  = 0
    @test_length = 1
    BenchTests.display_header(h)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Changes the seed each time its called to stay random.
  #---------------------------------------------------------------------------------------------------------
  def ranged_rand(seed, max)
    # https://ruby-doc.org/core-2.2.0/Random.html
    extra_step = Random.new(max + seed)
    return extra_step.rand(max) + rand(max) % max
    #string = Random.new.bytes(10) # random string
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw column definition header over string information table display.
  #---------------------------------------------------------------------------------------------------------
  def self.display_header(h = '')
    BenchTests.showText("------------------------------------------------------------------\n")
    BenchTests.showText("Name of Test: #{h}\t\tuser\tsystem\ttotal\t(  real)\n")
    BenchTests.showText("------------------------------------------------------------------\n")
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Draw endex footer information.
  #---------------------------------------------------------------------------------------------------------
  def self.display_footer()
    BenchTests.showText("------------------------------------------------------------------\n")
    BenchTests.showText("!ENDED!\n")
    GC.start # calls the garbage collector after each group test is finished
  end
  #---------------------------------------------------------------------------------------------------------
  #D: All text writes are funneled through here. This can be set up to clone printed text and send it to GUI
  #D: or any Logger, also displays the information directly into the console or can write to a file.
  #---------------------------------------------------------------------------------------------------------
  def self.showText(string)
    print(string)
  end
end

#===============================================================================================================================
# Misc classes used in stress testing. (Things that take word to apply artificial loads and things of this nature.)
#===============================================================================================================================
class StressAux_Class
  def mathspeed(x, y)
    int = x ^ y
    return int
  end
end
#---------------------------------------------------------------------------------------------------------
module StressAux_Module
  def self.mathspeed(x, y)
    int = x ^ y
    return int
  end
end

#===============================================================================================================================
# Run some tests: Takes the Runtime arguments and makes sense of them. Then applies this to the BenchTest suite.
benchmarkTesting = BenchTests.new()
# check run time argument flags
case ARGV.first
when "--run"
  test_id = ARGV[ARGV.index("--run") + 1]
  int_id = test_id.to_i()
  if int_id > 0
    RUN_TEST = int_id.freeze()
  else
    RUN_TEST = test_id.freeze()
  end
  puts "Running Benchmark for: #{RUN_TEST}."
else
  RUN_TEST = nil
  puts "Running Default mode. #{ARGV}"
end
# decide what the user is asking and hand it off to the Class.
if RUN_TEST
  if RUN_TEST == 'quick_bench'
    BenchTests.quick_bench()
  else # run one specific test
    if RUN_TEST.is_a?(Integer)
      run_for_times = 10_000
      arg_passed_times = ARGV.index("--times")
      run_for_times = ARGV[arg_passed_times + 1].to_i() if arg_passed_times
      BenchTests.showText(benchmarkTesting.run_bench(RUN_TEST, run_for_times))
      BenchTests.display_footer()
    else # running a group of tests
      benchmarkTesting.run(RUN_TEST)
    end
  end
else # running everything
  benchmarkTesting.run_all()
end


#===============================================================================================================================
# This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either Version 3 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along with this library; if not, write to the Free 
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#===============================================================================================================================
