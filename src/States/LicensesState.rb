#=====================================================================================================================
# !!!   LicensesState.rb  |  This is the Stage that shows the end user associated Licensing agreements.
#=====================================================================================================================
class LicensesState
  #---------------------------------------------------------------------------------------------------------
  # Create klass object.
  def initialize
    @textWall = GUI::TextWall.new(
      text: Gosu::LICENSES
    )
  end

  #---------------------------------------------------------------------------------------------------------
  # Update loop, where things get up to date!
  def update
    return if $application.nil?

    @textWall.update
  end

  #---------------------------------------------------------------------------------------------------------
  # Draw to screen.
  def draw
    return if $application.nil?

    @textWall.draw
  end

  #---------------------------------------------------------------------------------------------------------
  # Called when the menu is shut, it releases things back to GC.
  def dispose
    @textWall.dispose
  end
end
