#===============================================================================================================================
# !!! InputControls.rb   |  Manages the button input across all classes.
#===============================================================================================================================
class InputControls
=begin
Keeps track of all User defined input mappings and current button/key states for Input related statments.
--------------------------------------       --------------------------------------       --------------------------------------
         Avaliable Control Schemes:                           |                Tack Buttons: *For an xbox 360 Controler*     
  --------------------------------------                      |                             
           Menu Navigation                                    |                             
            :menu_up                                          |                             gp_0 = A
            :menu_down                                        |                             gp_1 = B
            :menu_left                                        |                             gp_2 = X
            :menu_right                                       |                             gp_3 = Y
            :menu_scroll_up                                   |                             gp_4 = Back
            :menu_scroll_down                                 |                             gp_5 = XBOX button
            :menu_action                                      |                             gp_6 = Start
  --------------------------------------                      |                             gp_7 = LS down
            Player Controls                                   |                             gp_8 = RS down
            :move_up                                          |                             gp_9 = LB
            :move_down                                        |                             gp_10 = RB
            :move_left                                        |                             gp_11 = LT
            :move_right                                       |                             gp_12 = RT
            :move_jump                                        |                             
            :move_sprint                                      |                             
            :attack_one                                       |
            :pause_menu                                       |                                          
  --------------------------------------                      |                   Digital Pad and Joy Stick:
           Misc Standards                                     |                              gp_down
            :action_key                                       |                              gp_up
            :mouse_lclick                                     |                              gp_left
            :mouse_rclick                                     |                              gp_right
            :cancel_action                                    |                **  Does ALL anolog stick input **
            :debug_action_one                                 |                                          
            :debug_action_two                                 |

--------------------------------------       --------------------------------------       --------------------------------------
Basic Use:
   $controls.key_press?(:move_left)      -=- Check to see if any input key used for player movement to the left has been triggered.
   $controls.holding?(:move_left)
   $controls.key_press?(:mouse_lclick)   -=- Check to see if a key/button trigger was depresed responsable for mouse clicking.
   $controls.trigger?(:mouse_lclick)
        *( Will only use a :symbol from the @@Controls table )*
                       --------------------------------------   
Advanced Use:
    $controls.holding?(:left , true)     -=- Check single button value for depression. Uses symbol to check if that button is 
                                              being held down.
    $controls.trigger?(:l_clk, true)     -=- Check single button value for trigger, was or is being depressed but was only 
                                              triggered once.
        *( Can use any Gosu or @@table button :symbol )*
                       --------------------------------------   
                       
To make changes the Control Scheme table you can use:
   $controls.Controls[:Scheme_Name].push(:New_Key)           -=- Adds a new button to control scheme.
   $controls.Controls[:Scheme_Name].delete(:Removed_Key)     -=- Removes button from control scheme.
   
Changing schemes:
   $controls.Controls.delete(:Remove_Scheme)     -=- Removes control shceme from mapping.
   $controls.Controls[:New_Scheme] = [:buttons]  -=- Creates a new control scheme for mapping.
--------------------------------------       --------------------------------------       --------------------------------------
Most of the game input is wrapped into Chingu::Window dues to the way Gosu recives calls back a button key input it will pass it 
  to Program ( @@parent_window ) class by the use of:
     
   + virtual void button_down(Gosu::Button) {}  +  Which is handed off to the same @@parent_window function name.
 The above function is called before update when the user pressed a button while the window had the focus.
          
   + virtual void button_up(Gosu::Button) {}    +  Which is handed off to the same @@parent_window function name.
 Same as the above for button_down, but instead called when the user has released a button.
 
This and more information on Gosu C Headers can be found here:  https://www.libgosu.org/cpp/namespace_gosu.html
--------------------------------------       --------------------------------------       --------------------------------------
=end #--------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------
# Table of mapped inputs for a US Qwerty keyboard, A standard mouse, and an Xbox Controller in windows at least...
#-------------------------------------------------------------------------------------------------------------------------------
  @@table = {
    :right       =>  79, :left        =>  80, :down     =>  81, :up       =>  82, :period    =>  54, :question   =>  56,
    :collon      =>  51, :equils      =>  46, :comma    =>  54, :dash     =>  45, :tiddle    =>  53, :fslash     =>  49, 
    :openbracket =>  47, :closebraket =>  48, :quote    =>  48, :lshift   => 225, :rshift    => 229, :pause      =>  72,
    :l_clk       => 256, :m_clk       => 257, :r_clk    => 258, :mouse_wu => 259, :mouse_wd  => 260,
    :return      =>  40, :backspace   =>  42, :space    =>  44, :esc      =>  41, :tab       =>  43,
    :rctrl       => 228, :lalt        => 226, :ralt     => 230,
    #--------------------------------------
    :end        =>  77, :home        =>  74, :ins         =>  73, :del      =>  76, :lwinkey   => 227, :rwinkey  => 231,
    :capslock   =>  57, :scrolllock  =>  71, :numlock     =>  83, :pageup   =>  75, :pagedwn   =>  78, 
    :p_enter    =>  88, :padadd      =>  87, :padsub      =>  86, :padmulti =>  85, :paddivide =>  84,
    :vol_down   => 129, :vol_up      => 128, :printscreen =>  70, :taskkey  => 101, :pdecimal  =>  99,
    #--------------------------------------
    :gp_lstick_left => 293, :gp_lstick_right => 294, :gp_lstick_up => 295, :gp_lstick_down => 296,
    :gp_rstick_left => 273, :gp_rstick_right => 274, :gp_rstick_up => 275, :gp_rstick_down => 276
  }
  id = 0; temp = {} # ID of the key and temp working container.
  #--------------------------------------
  # Add all the letter keys on the keyboard.
  for l in "a".."z"; temp.store("let_#{l}".to_sym, 4 + id); id += 1; end; id = 0; @@table.update(temp); temp = {} 
  #--------------------------------------
  # Add all of the number keys of the keyboard.
  for n in "1".."9"; temp.store("num_#{n}".to_sym, 30 + id); id += 1; end; id = 0; temp.store("num_0".to_sym, 39)
  @@table.update(temp); temp = {} 
  #--------------------------------------
  # Add the Key pad numbers.
  for n in "1".."9"; temp.store("pad_#{n}".to_sym, 89 + id); id += 1; end; id = 0; temp.store("pad_0".to_sym, 98)
  @@table.update(temp); temp = {}
  #--------------------------------------
  # Add all of the F-keys.
  for n in "1".."12"; temp.store("f_#{n}".to_sym,  58 + id); id += 1; end; @@table.update(temp); temp = {}
  #--------------------------------------
  id = temp = nil # clear temp variables.

#===============================================================================================================================
# Controls Class Object
#===============================================================================================================================
  # Print what ever input key is pressed to the console and logger if enabled. makes it easier to see which 
  # key is mapped to what button statement.
  @@PRINT_INPUT_KEY = false #DV Boolean value that enables current input label print out.
  if @@PRINT_INPUT_KEY; puts("Debugging Input Controls, printing information to console."); end
  #--------------------------------------
  @@buttons_down = [] #DV All buttons currently being held down.
  @@buttons_up   = [] #DV Any button that was recently held down, but was released.
  @@triggered    = [] #DV Buttons depressed that do not count as being depressed when they are held down.
  @@holding      = []
  @@parent_window = nil
  #--------------------------------------
  INPUT_LAG = 1 # Time to wait in between @@buttons_down clearing. (* Mouse wheel buttons have trouble when set to 0 *)
  #---------------------------------------------------------------------------------------------------------
  #D: Create the input class variables.
  #---------------------------------------------------------------------------------------------------------
  def initialize(parent_window)
    @@parent_window = parent_window
    @prevously_pressed_key = nil #DV Keeps track of previous key pressed as to not spam the console when printing input keys.
    return unless $controls.nil?
    reset_defualts()
    $controls  = self # Make sure that only one instance of input is active at any given time.
    @triggers  = []   #DV Adds all trigger keys to @@triggered at the same time.
    @input_lag = 0    #DV Makes sure that system has enough time to detect all buttons depressed.
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Reset the control scheme back to default.
  #---------------------------------------------------------------------------------------------------------
  def reset_defualts
    @@Controls = { #DV Hash container for the current control scheme.
      #--------------------------------------
      # In game menu navigation
      #--------------------------------------
      :menu_up          => [:up, :gp_up],
      :menu_down        => [:down, :gp_down],
      :menu_left        => [:left, :gp_left],
      :menu_right       => [:right, :gp_right],
      :menu_scroll_up   => [:gp_9 , :mouse_wu],
      :menu_scroll_down => [:gp_10, :mouse_wd],
      :menu_action      => [:l_clk, :gp_0, :space, :return],
      #--------------------------------------
      # Player controls
      #--------------------------------------
      :move_up      => [:up, :let_w, :gp_up],
      :move_down    => [:down, :let_s, :gp_down],
      :move_left    => [:left, :let_a, :gp_left],
      :move_right   => [:right, :let_d, :gp_right],
      :move_jump    => [:gp_0, :space],
      :move_sprint  => [:gp_12, :lshift],
      :attack_one   => [:right_ctrl, :gp_2],
      :pause_menu   => [:esc, :gp_6],
      #--------------------------------------
      # Standards
      #--------------------------------------
      :action_key       => [:let_f, :gp_1],
      :mouse_lclick     => [:l_clk],
      :mouse_rclick     => [:r_clk],
      :cancel_action    => [:esc, :gp_4],
      :debug_action_one => [:left_ctrl],
      :debug_action_two => [:return, :gp_10],
      #--------------------------------------
      :shift => [:lshift, :rshift] # general shift button
    }
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Return character key of current input, this is used text input fields generally.
  #---------------------------------------------------------------------------------------------------------
  def grab_characters()
    key = '' # string value of input key
    @@buttons_down.each do |butt_id|
      butt_chr = @@table.key(butt_id).to_s
      #--------------------------------------
      # letters
      if butt_chr.include?("let_")
        key = butt_chr.sub!('let_', '')
        if self.holding?(:shift) # capital letter?
          key.capitalize!
        end
      #--------------------------------------
      # numbers
      elsif butt_chr.to_s.include?("num_")
        key = butt_chr.sub!('num_', '')
        if self.holding?(:shift) # special char?
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
      elsif butt_chr.to_s.include?("pad_")
        key = butt_chr.sub!('pad_', '')
      #--------------------------------------
      # functions
      elsif %w[backspace return del space tab].include?(butt_chr.to_s)
        key = butt_chr.to_s
      #--------------------------------------
      # anything else
      else
        #puts("There is an unknown character being depressed! (#{butt_id})")
      end
    end
    return key
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Central basic use for control scheme button input checks.
  #---------------------------------------------------------------------------------------------------------
  def key_press?(key_symbol)
    return false if @@parent_window.nil?
    assigned_buttons = @@Controls[key_symbol]
    if assigned_buttons.nil?
      puts("Control settings for (#{key_symbol}) where not found!")
      return false
    end
    #--------------------------------------
    for button in assigned_buttons
      input = @@buttons_down.include?(@@table[button]) # check to make sure no buttons threw Win32API are depressed
      break if input
    end
    return input
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Updates the input client, this is called on @@parent_window.update so no need to add redundancy to it!
  #---------------------------------------------------------------------------------------------------------
  def update()
    return if @@parent_window.nil?
    #print_input_keys if @@PRINT_INPUT_KEY
    #--------------------------------------
    # sometimes keys are depressed and released very quickly (i.e. Mouse Wheel functions) and need extra time to register amongst classes.
    if @input_lag > 0
      @input_lag -= 1
      return
    end
    #--------------------------------------
    # update input array of buttons being held down.
    @@buttons_down = @@buttons_down - @@buttons_up # remove buttons held down if they where released.
    #puts "Buttons up (#{@@buttons_up}) | Buttons down (#{@@buttons_down})"
    #print("Buttons have changed: (#{@@buttons_down})\n")
    #--------------------------------------
    # add any key triggers to class @@triggered at the same time so each class using trigger? get a chance to check shared input keys
    @@triggered = @@triggered + @triggers
    @triggers = []
    #--------------------------------------
    # clear any triggers when the key that was triggered is released
    @@buttons_up.each { |id|
      if @@triggered.include?(id)
        @@triggered.delete(id)
      end
    }
    @@buttons_up = [] # will hold onto all recent button releases unless cleared.
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Check to see if (key_symbol = :button_symbol , id_only = true) or (key_symbol = @@Controls[:symbol]) is currently being held down.
  #---------------------------------------------------------------------------------------------------------
  def holding?(key_symbol, id_only = false)
    unless id_only # using localized key mapping
      assigned_buttons = @@Controls[key_symbol]
      if assigned_buttons.nil?
        puts("Control settings for (#{key_symbol}) where not found!")
        return false
      end
    else # used single key id instead
      assigned_buttons = [key_symbol]
    end
    #--------------------------------------
    input = false
    for button in assigned_buttons
      input |= @@buttons_down.include?(@@table[button]) # check to make sure no buttons via call back are depressed
      #input |= @@holding.include?(@@table[button])
      #print("#{key_symbol} | #{assigned_buttons} ( #{button} ) = #{@@table[button]} [ #{@@holding} ]\n")
      break if input
    end
    return input # return value of button(s) state
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Check to seed if (key_symbol = :button_symbol , id_only = true) or (key_symbol = @@Controls[:symbol]) was depressed,
  #D: count it once and remove from input.
  #---------------------------------------------------------------------------------------------------------
  def trigger?(key_symbol, id_only = false)
    unless id_only # using localized key mapping
      assigned_buttons = @@Controls[key_symbol]
      if assigned_buttons.nil?
        puts("Control settings for (#{key_symbol}) where not found!")
        return false
      end
    else # used single key id instead
      assigned_buttons = [key_symbol]
    end
    #--------------------------------------
    for button in assigned_buttons
      #puts "Control settings for (#{key_symbol}) - #{button} = #{@@buttons_down}"
      if @@buttons_down.include?(@@table[button])
        #print("checking input trigger for #{key_symbol} butt:(#{button})\n")
        unless @@triggered.include?(@@table[button])
          @triggers << @@table[button]
          #puts ("(#{key_symbol}) Button was triggered (#{@@triggered})")if input # print all current triggered keys
          return true
        end
      end
    end
    #--------------------------------------
    return false 
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called on @@parent_window state swaps and pushes.
  #---------------------------------------------------------------------------------------------------------
  def clear_state_change
    @@buttons_down = []
    @@buttons_up   = []
    @@triggered    = [] 
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Returns the symbol attached to the key id.
  #---------------------------------------------------------------------------------------------------------
  def get_input_symbol(id)
    return @@table.key(id)
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Returns the id attached to the key symbol.
  #---------------------------------------------------------------------------------------------------------
  def get_input_id(symbol)
    #puts "#{symbol}"
    return @@table[symbol]
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Get console confirmation that hand off to global was completed.
  #---------------------------------------------------------------------------------------------------------
  def test_print
    puts("Button Control global was created successfully.")
    # extra print data points for @@parent_window klass.
    #print("#{@@parent_window.methods.join(",\n")}\n")
    #print("#{@@parent_window.instance_variables.join(",\n")}\n")
    #print("#{Gosu::Window.methods.join(",\n")}\n")
    #print("#{Gosu::Window.instance_variables.join(",\n")}\n") # <- there are none
    #exit
    puts "--------------------------------------------------------------------" # usually the last boot information
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Announce debug state so other classes can adjust if needed.
  #---------------------------------------------------------------------------------------------------------
  def debugging?
    return @@PRINT_INPUT_KEY
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Prints the current keyboard/game-pad input symbol and value to console.
  #---------------------------------------------------------------------------------------------------------
  def print_input_keys
    return if @@parent_window.nil?
    butt_id = @@parent_window.get_input_key 
    #print("#{@@parent_window.input}\n"); exit # display current keys mapped to methods for the @@parent_window class
    return if butt_id.nil? or @prevously_pressed_key == butt_id
    @prevously_pressed_key = butt_id
    #print("(#{@@table.key(butt_id)}) for Win32API/n")
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called when a key is depressed. ID can be an integer or an array of integers that reference input symbols.
  #---------------------------------------------------------------------------------------------------------
  def button_down(id)
    unless @@buttons_down.include?(id)
      @input_lag = INPUT_LAG
      @@buttons_down << id
    end
    @@holding << id unless @@holding.include?(id)
    return unless @@PRINT_INPUT_KEY
    #print("Buttons currently held down: #{@@buttons_down} T:#{@@triggered}\n")
    print("Window button pressed: (#{id}) which is (#{$controls.get_input_symbol(id).to_s})\n")
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Called when a button was held but was released. ID can be an integer or an array of integers that 
  #D: reference input symbols.
  #---------------------------------------------------------------------------------------------------------
  def button_up(id)
    @@buttons_up << id unless @@buttons_up.include?(id)
    @@holding.delete(id) if @@holding.include?(id)
    # debug information printing
    return unless @@PRINT_INPUT_KEY
    #print("Window button released: (#{id}) which is (#{@@table.key(id)}) T:(#{@@triggered})\n")
    #print("Buttons recently released: #{@@buttons_up}\n")
  end
  #---------------------------------------------------------------------------------------------------------
  #D: Check and return input registers to game pad 0 joystick left. *Gosu for some reason joins with right stick.
  #---------------------------------------------------------------------------------------------------------
  def left_joy_stick
    # [up, down, left, right]
    directions = [false, false, false, false]
    if @@parent_window.button_down?(295)    # stick up
      directions[0] = true
    elsif @@parent_window.button_down?(296) # stick down
      directions[1] = true
    elsif @@parent_window.button_down?(293) # stick left
      directions[2] = true
    elsif @@parent_window.button_down?(294) # stick right
      directions[3] = true
    end
    return directions
  end
  #---------------------------------------------------------------------------------------------------------
  #D:Check and return input registers to game pad 0 joystick right. *Gosu for some reason joins with left stick.
  #---------------------------------------------------------------------------------------------------------
  def right_joy_stick
    # [up, down, left, right]
    directions = [false, false, false, false]
    if @@parent_window.button_down?(275)    # stick up
      directions[0] = true
    elsif @@parent_window.button_down?(276) # stick down
      directions[1] = true
    elsif @@parent_window.button_down?(273) # stick left
      directions[2] = true
    elsif @@parent_window.button_down?(274) # stick right
      directions[3] = true
    end
    return directions
  end
end


#===============================================================================================================================
# Copyright (C) 2017 Wiggles
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#===============================================================================================================================
