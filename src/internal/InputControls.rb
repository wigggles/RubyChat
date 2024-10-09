#=====================================================================================================================
# !!! InputControls.rb   |  Manages the button input that allows mapping and additional check methods.
#=====================================================================================================================
class InputControls
  # Keeps track of all User defined input mappings and current button/key states for Input related statements.
  # ----------------------------       --------------------------------------       ------------------------------------
  #          Availabel Control Schemes:                           |          Tack Buttons: *For an xbox 360 Controller*
  #   --------------------------------------                      |
  #            Menu Navigation                                    |
  #             :menu_up                                          |                             gp_0 = A
  #             :menu_down                                        |                             gp_1 = B
  #             :menu_left                                        |                             gp_2 = X
  #             :menu_right                                       |                             gp_3 = Y
  #             :menu_scroll_up                                   |                             gp_4 = Back
  #             :menu_scroll_down                                 |                             gp_5 = XBOX button
  #             :menu_action                                      |                             gp_6 = Start
  #   --------------------------------------                      |                             gp_7 = LS down
  #             Player Controls                                   |                             gp_8 = RS down
  #             :move_up                                          |                             gp_9 = LB
  #             :move_down                                        |                             gp_10 = RB
  #             :move_left                                        |                             gp_11 = LT
  #             :move_right                                       |                             gp_12 = RT
  #             :move_jump                                        |
  #             :move_sprint                                      |
  #             :attack_one                                       |
  #             :pause_menu                                       |
  #   --------------------------------------                      |                   Digital Pad and Joy Stick:
  #            Misc Standards                                     |                              gp_down
  #             :action_key                                       |                              gp_up
  #             :mouse_lclick                                     |                              gp_left
  #             :mouse_rclick                                     |                              gp_right
  #             :cancel_action                                    |                **  Does ALL analog stick input **
  #             :debug_action_one                                 |
  #             :debug_action_two                                 |
  #
  # ----------------------------       ------------------------------------       --------------------------------------
  # Basic Use:
  #    controls = InputControls.new
  #
  #    controls.key_press?(:move_left)      -=- Check to see if any input key used for player movement to the left
  #    controls.holding?(:move_left)              has been triggered.
  #    controls.key_press?(:mouse_lclick)   -=- Check to see if a key/button trigger was depressed responsible for
  #    controls.trigger?(:mouse_lclick)           mouse clicking.
  #         *( Will only use a :symbol from the @function_map table )*
  #                        --------------------------------------
  # Advanced Use:
  #     controls.holding?(:left , true)     -=- Check single button value for depression. Uses symbol to check if that
  #                                                button is being held down.
  #     controls.trigger?(:l_clk, true)     -=- Check single button value for trigger, was or is being depressed but
  #                                                was only triggered once.
  #         *( Can use any Gosu or @table button :symbol )*
  #                        --------------------------------------
  #
  # To make changes the Control Scheme table you can use:
  #    controls.function_map[:Scheme_Name].push(:New_Key)           -=- Adds a new button to control scheme.
  #    controls.function_map[:Scheme_Name].delete(:Removed_Key)     -=- Removes button from control scheme.
  #
  # Changing schemes:
  #    controls.function_map.delete(:Remove_Scheme)     -=- Removes control scheme from mapping.
  #    controls.function_map[:New_Scheme] = [:buttons]  -=- Creates a new control scheme for mapping.
  # ----------------------------       ------------------------------------       --------------------------------------
  # Most of the game input is wrapped into Gosu::Window dues to the way Gosu receives calls back a button key input
  #   it will pass it to Program ( $application ) class by the use of:
  #
  #    + virtual void button_down(Gosu::Button) {}  +  Which is handed off to the same $application function name.
  #  The above function is called before update when the user pressed a button while the window had the focus.
  #
  #    + virtual void button_up(Gosu::Button) {}    +  Which is handed off to the same $application function name.
  #  Same as the above for button_down, but instead called when the user has released a button.
  #
  # This and more information on Gosu C Headers can be found here:  https://www.libgosu.org/cpp/namespace_gosu.html
  # ----------------------------       ------------------------------------       --------------------------------------
  # =end #--------------------------------------------------------------------------------------------------------------
  # Table of mapped inputs for a US Qwerty keyboard, A standard mouse, and an Xbox Controller in windows at least...
  #---------------------------------------------------------------------------------------------------------------------
  def map_keyboard
    @table = {
      right: 79, left: 80, down: 81, up: 82, period: 55, question: 56,
      colon: 51, equals: 46, comma: 54, dash: 45, tilde: 53, fslash: 49,
      openbracket: 47, closebracket: 48, quote: 52, lshift: 225, rshift: 229, pause: 72,
      l_clk: 256, m_clk: 257, r_clk: 258, mouse_wu: 259, mouse_wd: 260,
      return: 40, backspace: 42, space: 44, esc: 41, tab: 43,
      lctrl: 228, rctrl: 224, lalt: 226, ralt: 230,
        #--------------------------------------
      end: 77, home: 74, ins: 73, del: 76, lwinkey: 227, rwinkey: 231,
      capslock: 57, scrolllock: 71, numlock: 83, pageup: 75, pagedwn: 78,
      p_enter: 88, padadd: 87, padsub: 86, padmulti: 85, paddivide: 84,
      vol_down: 129, vol_up: 128, printscreen: 70, taskkey: 101, pdecimal: 99,
      #--------------------------------------
      gp_lstick_left: 293, gp_lstick_right: 294, gp_lstick_up: 295, gp_lstick_down: 296,
      gp_rstick_left: 273, gp_rstick_right: 274, gp_rstick_up: 275, gp_rstick_down: 276
    }
    id = 0
    temp = {} # ID of the key and temp working container.
    #--------------------------------------
    # Add all the letter keys on the keyboard.
    for l in 'a'..'z'
      temp.store("let_#{l}".to_sym, 4 + id)
      id += 1
 end
    id = 0
    @table.update(temp)
    temp = {}
    #--------------------------------------
    # Add all of the number keys of the keyboard.
    for n in '1'..'9'
      temp.store("num_#{n}".to_sym, 30 + id)
      id += 1
 end
    id = 0
    temp.store('num_0'.to_sym, 39)
    @table.update(temp)
    temp = {}
    #--------------------------------------
    # Add the Key pad numbers.
    for n in '1'..'9'
      temp.store("pad_#{n}".to_sym, 89 + id)
      id += 1
 end
    id = 0
    temp.store('pad_0'.to_sym, 98)
    @table.update(temp)
    temp = {}
    #--------------------------------------
    # Add all of the F-keys.
    for n in '1'..'12'
      temp.store("f_#{n}".to_sym, 58 + id)
      id += 1
 end
    @table.update(temp)
    #--------------------------------------
    nil # clear temp variables.
  end

  #=====================================================================================================================
  # Controls Class Object
  #=====================================================================================================================
  attr_accessor :function_map

  # Print what ever input key is pressed to the console and logger if enabled. makes it easier to see which
  # key is mapped to what button statement.
  PRINT_INPUT_KEY = false # Boolean value that enables current input label print out.
  puts('Debugging Input Controls, printing information to console.') if PRINT_INPUT_KEY
  #--------------------------------------
  INPUT_LAG = 0  # Time to wait in between @buttons_down clearing. (* Mouse wheel buttons have trouble when set to 0 *)
  KEY_REPEAT = 1 # While holding down a key, time between repeated character input.
  #---------------------------------------------------------------------------------------------------------
  # Create the input class variables.
  #---------------------------------------------------------------------------------------------------------
  def initialize
    @previously_pressed_key = nil # Keeps track of previous pressed, only when printing input debugging.
    map_keyboard
    reset_defaults
    @triggers  = []       # Adds all trigger keys to @triggered at the same time.
    @input_lag = 0        # Makes sure that system has enough time to detect all buttons depressed.
    @input_repeat = 0     # Time between repeated character input when holding down a key.
    @last_character = nil # the last character to be used during an input repeat for holding down a key.
    @buttons_down = []    # All buttons currently being held down.
    @buttons_up   = []    # Any button that was recently held down, but was released.
    @triggered    = []    # Buttons depressed that do not count as being depressed when they are held down.
    @holding      = []
  end

  #---------------------------------------------------------------------------------------------------------
  # Reset the control scheme back to default.
  #---------------------------------------------------------------------------------------------------------
  def reset_defaults
    @function_map = { # Hash container for the current control scheme.
      #--------------------------------------
      # In game menu navigation
      #--------------------------------------
      menu_up: %i[up gp_up],
      menu_down: %i[down gp_down],
      menu_left: %i[left gp_left],
      menu_right: %i[right gp_right],
      menu_scroll_up: %i[gp_9 mouse_wu],
      menu_scroll_down: %i[gp_10 mouse_wd],
      menu_action: %i[l_clk gp_0 space return],
      #--------------------------------------
      # Player controls
      #--------------------------------------
      move_up: %i[up let_w gp_up],
      move_down: %i[down let_s gp_down],
      move_left: %i[left let_a gp_left],
      move_right: %i[right let_d gp_right],
      move_jump: %i[gp_0 space],
      move_sprint: %i[gp_12 lshift],
      attack_one: %i[right_ctrl gp_2],
      pause_menu: %i[esc gp_6],
      #--------------------------------------
      # Standards
      #--------------------------------------
      action_key: %i[let_f gp_1],
      mouse_lclick: [:l_clk],
      mouse_rclick: [:r_clk],
      cancel_action: %i[esc gp_4],
      debug_action_one: [:left_ctrl],
      debug_action_two: %i[return gp_10],
      #--------------------------------------
      shift: %i[lshift rshift] # general shift button
    }
  end

  #---------------------------------------------------------------------------------------------------------
  # Return character key of current input, this is used text input fields generally. Can only be called
  # once globally as part of an update loop. It does alright, should check out GOSU Window::TextField
  # which may perform better.
  #---------------------------------------------------------------------------------------------------------
  def get_text_input
    key = '' # string value of input key
    button_id = nil
    # keep up with key repeat hold character input
    @input_repeat -= 1 if @input_repeat > 0
    @buttons_down.each do |butt_id|
      butt_chr = @table.key(butt_id).to_s
      # ignore keys not used for typing text
      next if %w[lshift rshift lalt ralt rctrl lctrl mouse_wu mouse_wd l_clk m_clk r_clk].include?(butt_chr.to_s)

      #--------------------------------------
      # letters
      if butt_chr.include?('let_')
        key = butt_chr.sub!('let_', '')
        key.capitalize! if holding?(:shift) # capital letter?
      #--------------------------------------
      # numbers
      elsif butt_chr.to_s.include?('num_')
        key = butt_chr.sub!('num_', '')
        if holding?(:shift) # special char?
          case key
          when '1' then key = '!'
          when '2' then key = '@'
          when '3' then key = '#'
          when '4' then key = '$'
          when '5' then key = '%'
          when '6' then key = '^'
          when '7' then key = '&'
          when '8' then key = '*'
          when '9' then key = '('
          when '0' then key = ')'
          end
        end
      elsif butt_chr.to_s.include?('pad_')
        key = butt_chr.sub!('pad_', '')
      #--------------------------------------
      # functions
      elsif %w[backspace return del space tab].include?(butt_chr.to_s)
        key = butt_chr.to_s
      #--------------------------------------
      # specials
      elsif %w[period question colon equals comma dash tilde fslash openbracket closebracket
               quote].include?(butt_chr.to_s)
        if holding?(:shift)
          case butt_chr.to_s
          when 'period' then key = '>'
          when 'question' then key = '?'
          when 'colon' then key = ':'
          when 'equals' then key = '+'
          when 'comma' then key = '<'
          when 'dash' then key = '_'
          when 'tilde' then key = '~'
          when 'fslash' then key = '|'
          when 'openbracket' then key = '{'
          when 'closebracket' then key = '}'
          when 'quote' then key = '"'
          end
        else
          case butt_chr.to_s
          when 'period' then key = '.'
          when 'question' then key = '/'
          when 'colon' then key = ';'
          when 'equals' then key = '='
          when 'comma' then key = ','
          when 'dash' then key = '-'
          when 'tilde' then key = '`'
          when 'fslash' then key = '\\'
          when 'openbracket' then key = '['
          when 'closebracket' then key = ']'
          when 'quote' then key = '\''
          end
        end
      # puts("special character being depressed! (#{butt_id})-[#{butt_chr}] {#{key}}")
      #--------------------------------------
      # anything else
      else
        # puts("There is an unknown character being depressed! (#{butt_id})-[#{butt_chr}]")
      end
      if key != ''
        button_id = butt_id
        break
      end
    end
    # repeated input speed when holding same character
    if key == ''
      @input_repeat = 0
      @last_character = nil
      return key
    elsif @last_character == button_id
      return '' if @input_repeat > 0

      @input_repeat = KEY_REPEAT
    else
      @input_repeat = KEY_REPEAT * 20
      @last_character = button_id
    end
    # puts "key (#{key}) '#{@last_character}' keys: #{@buttons_down.size}"
    key
  end

  #---------------------------------------------------------------------------------------------------------
  # Central basic use for control scheme button input checks.
  #---------------------------------------------------------------------------------------------------------
  def key_press?(key_symbol)
    return false if $application.nil?

    assigned_buttons = @function_map[key_symbol]
    if assigned_buttons.nil?
      puts("Control settings for (#{key_symbol}) were not found!")
      return false
    end
    #--------------------------------------
    for button in assigned_buttons
      input = @buttons_down.include?(@table[button]) # check to make sure no buttons threw Win32API are depressed
      break if input
    end
    input
  end

  #---------------------------------------------------------------------------------------------------------
  # Updates the input client, this is called on $application.update so no need to add redundancy to it!
  #---------------------------------------------------------------------------------------------------------
  def update
    return if $application.nil?

    # print_input_keys if PRINT_INPUT_KEY
    #--------------------------------------
    # sometimes keys are depressed and released very quickly (i.e. Mouse Wheel functions) and need extra time
    # to register amongst all other classes.
    if @input_lag > 0
      @input_lag -= 1
      return
    end
    #--------------------------------------
    # update input array of buttons being held down.
    @buttons_down -= @buttons_up # remove buttons held down if they where released.
    # puts "Buttons up (#{@buttons_up}) | Buttons down (#{@buttons_down})"
    # print("Buttons have changed: (#{@buttons_down})\n")
    #--------------------------------------
    # add any key triggers to class @triggered at the same time so each class using trigger? get a chance
    # to check shared input keys.
    @triggered += @triggers
    @triggers = []
    #--------------------------------------
    # clear any triggers when the key that was triggered is released
    @buttons_up.each do |id|
      @triggered.delete(id) if @triggered.include?(id)
    end
    @buttons_up = [] # will hold onto all recent button releases unless cleared.
  end

  #---------------------------------------------------------------------------------------------------------
  # Check to see if (key_symbol = :button_symbol , id_only = true) or (key_symbol = @function_map[:symbol])
  # is currently being held down.
  #---------------------------------------------------------------------------------------------------------
  def holding?(key_symbol, id_only = false)
    if id_only # used single key id instead
      assigned_buttons = [key_symbol]
    else # using localized key mapping
      assigned_buttons = @function_map[key_symbol]
      if assigned_buttons.nil?
        puts("Control settings for (#{key_symbol}) were not found!")
        return false
      end
    end
    #--------------------------------------
    input = false
    for button in assigned_buttons
      input |= @buttons_down.include?(@table[button]) # buttons are depressed?
      # input |= @holding.include?(@table[button])
      # print("#{key_symbol} | #{assigned_buttons} ( #{button} ) = #{@table[button]} [ #{@holding} ]\n")
      break if input
    end
    input # return value of button(s) state
  end

  #---------------------------------------------------------------------------------------------------------
  # Check to seed if (key_symbol = :button_symbol , id_only = true) or (key_symbol = @function_map[:symbol])
  # was depressed, count it once and remove from input.
  #---------------------------------------------------------------------------------------------------------
  def trigger?(key_symbol, id_only = false)
    if id_only # used single key id instead
      assigned_buttons = [key_symbol]
    else # using localized key mapping
      assigned_buttons = @function_map[key_symbol]
      if assigned_buttons.nil?
        puts("Control settings for (#{key_symbol}) were not found!")
        return false
      end
    end
    #--------------------------------------
    for button in assigned_buttons
      # puts "Control settings for (#{key_symbol}) - #{button} = #{@buttons_down}"
      next unless @buttons_down.include?(@table[button])

      # print("checking input trigger for #{key_symbol} butt:(#{button})\n")
      next if @triggered.include?(@table[button])

      @triggers << @table[button]
      # print all current triggered keys:
      # puts ("(#{key_symbol}) Button was triggered (#{@triggered})")if input
      return true
    end
    #--------------------------------------
    false
  end

  #---------------------------------------------------------------------------------------------------------
  # Called on $application state swaps and pushes.
  #---------------------------------------------------------------------------------------------------------
  def clear_state_change
    @buttons_down = []
    @buttons_up   = []
    @triggered    = []
  end

  #---------------------------------------------------------------------------------------------------------
  # Returns the symbol attached to the key id.
  #---------------------------------------------------------------------------------------------------------
  def get_input_symbol(id)
    @table.key(id)
  end

  #---------------------------------------------------------------------------------------------------------
  # Returns the id attached to the key symbol.
  #---------------------------------------------------------------------------------------------------------
  def get_input_id(symbol)
    # puts "#{symbol}"
    @table[symbol]
  end

  #---------------------------------------------------------------------------------------------------------
  # Get console confirmation that hand off to global was completed.
  #---------------------------------------------------------------------------------------------------------
  def test_print
    puts('Button Control global was created successfully.')
    # extra print data points for $application klass.
    # print("#{$application.methods.join(",\n")}\n")
    # print("#{$application.instance_variables.join(",\n")}\n")
    # print("#{Gosu::Window.methods.join(",\n")}\n")
    # print("#{Gosu::Window.instance_variables.join(",\n")}\n") # <- there are none
    # exit
    puts '--------------------------------------------------------------------'
    # This is usually the last service startup seen information.
  end

  #---------------------------------------------------------------------------------------------------------
  # Announce debug state so other classes can adjust if needed.
  #---------------------------------------------------------------------------------------------------------
  def debugging?
    PRINT_INPUT_KEY
  end

  #---------------------------------------------------------------------------------------------------------
  # Prints the current keyboard/game-pad input symbol and value to console.
  #---------------------------------------------------------------------------------------------------------
  def print_input_keys
    return if $application.nil?

    butt_id = $application.get_input_key
    return if butt_id.nil? or @previously_pressed_key == butt_id

    @previously_pressed_key = butt_id
    # print("(#{@table.key(butt_id)}) for Win32API/n")
  end

  #---------------------------------------------------------------------------------------------------------
  # Called when a key is depressed. ID can be an integer or an array of integers that reference
  # input symbols.
  #---------------------------------------------------------------------------------------------------------
  def button_down(id)
    unless @buttons_down.include?(id)
      @input_lag = INPUT_LAG
      @buttons_down << id
    end
    @holding << id unless @holding.include?(id)
    return unless PRINT_INPUT_KEY

    # print("Buttons currently held down: #{@buttons_down} T:#{@triggered}\n")
    print("Window button pressed: (#{id}) which is (#{$application.controls.get_input_symbol(id)})\n")
  end

  #---------------------------------------------------------------------------------------------------------
  # Called when a button was held but was released. ID can be an integer or an array of integers that
  # reference input symbols.
  #---------------------------------------------------------------------------------------------------------
  def button_up(id)
    @buttons_up << id unless @buttons_up.include?(id)
    @holding.delete(id) if @holding.include?(id)
    # debug information printing
    nil unless PRINT_INPUT_KEY
    # print("Window button released: (#{id}) which is (#{@table.key(id)}) T:(#{@triggered})\n")
    # print("Buttons recently released: #{@buttons_up}\n")
  end

  #---------------------------------------------------------------------------------------------------------
  # Check and return input registers to game pad 0 joystick left. *Gosu for some reason joins with
  # right stick.
  #---------------------------------------------------------------------------------------------------------
  def left_joy_stick
    # [up, down, left, right]
    directions = [false, false, false, false]
    directions[0] = Gosu.button_down?(Gosu::GP_0_LEFT_STICK_Y_AXIS) # stick up
    directions[1] = Gosu.button_down?(Gosu::GP_0_LEFT_STICK_Y_AXIS) # stick down
    directions[2] = Gosu.button_down?(Gosu::GP_0_LEFT_STICK_X_AXIS) # stick left
    directions[3] = Gosu.button_down?(Gosu::GP_0_LEFT_STICK_X_AXIS) # stick right
    directions
  end

  #---------------------------------------------------------------------------------------------------------
  # Check and return input registers to game pad 0 joystick right. *Gosu for some reason joins with
  # left stick.
  #---------------------------------------------------------------------------------------------------------
  def right_joy_stick
    # [up, down, left, right]
    directions = [false, false, false, false]
    directions[0] = Gosu.button_down?(Gosu::GP_0_RIGHT_STICK_Y_AXIS) # stick up
    directions[1] = Gosu.button_down?(Gosu::GP_0_RIGHT_STICK_Y_AXIS) # stick down
    directions[2] = Gosu.button_down?(Gosu::GP_0_RIGHT_STICK_X_AXIS) # stick left
    directions[3] = Gosu.button_down?(Gosu::GP_0_RIGHT_STICK_X_AXIS) # stick right
    directions
  end

  #---------------------------------------------------------------------------------------------------------
  # Check basic move directions. Alternatively you can still take advantage of the Gosu keyboard mappings.
  # https://www.rubydoc.info/gems/gosu/Gosu
  # https://www.rubydoc.info/gems/gosu/Gosu#button_down%3F-class_method
  #---------------------------------------------------------------------------------------------------------
  def input_move?
    directions = [false, false, false, false]
    directions[0] = (Gosu.button_down?(Gosu::KB_UP) || Gosu.button_down?(Gosu::KB_W))    # move up
    directions[1] = (Gosu.button_down?(Gosu::KB_DOWN) || Gosu.button_down?(Gosu::KB_S))  # move down
    directions[2] = (Gosu.button_down?(Gosu::KB_LEFT) || Gosu.button_down?(Gosu::KB_A))  # move left
    directions[3] = (Gosu.button_down?(Gosu::KB_RIGHT) || Gosu.button_down?(Gosu::KB_D)) # move right
    directions
  end
end
