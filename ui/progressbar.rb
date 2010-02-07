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

class DoubleProgressBar < ProgressBar
  attr_accessor :maximum2, :value2, :bar2, :arrow2
  
  def initialize *args
    @maximum2 = 1
    @value2 = 0
    @bar2 = '-'
    @arrow2 = '>'
    super
  end
  
  def percentage2
    @value2.to_f / @maximum2.to_f
  end
  
  def template str
    @precap, @bar2, @arrow2, @bar, @arrow, @blank, @postcap = str.unpack 'aaaaaaa'
  end
  
  def redraw
    super
    @display.place y1, x1, @precap + (@bar2 * (percentage2 * (width - @precap.size - @postcap.size)) + @arrow2)
  end
end
end
end
