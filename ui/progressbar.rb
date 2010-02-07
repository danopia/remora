module Remora
module UI
class ProgressBar < Control
  attr_accessor :maximum, :value, :precap, :bar, :arrow, :blank, :postcap
  
  def initialize *args
    @maximum = 1
    @value = 0
    @precap = '['
    @bar = '='
    @arrow = '>'
    @blank = ' '
    @postcap = ']'
    super
  end
  
  def percentage
    @value.to_f / @maximum.to_f
  end
  
  def template str
    @precap, @bar, @arrow, @blank, @postcap = str.unpack 'aaaaa'
  end
  
  def redraw
    @display.place y1, x1, @precap + (@bar * (percentage * (width - @precap.size - @postcap.size)) + @arrow).ljust(width - @precap.size - @postcap.size, @blank) + @postcap
  end
end
end
end
