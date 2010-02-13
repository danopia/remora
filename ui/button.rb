module Remora
module UI
class Button < Label
  attr_accessor :handler
  
  def on_submit &blck
    @handler = blck
  end
  
  def handle_char char
    if char == "\n"
      @handler.call if @handler
    end
    #redraw
  end
  
  def text
    "[ #{@text} ]"
  end
  
  def redraw
    @display.cursor = false
    print @display.color(@display.active_control == self ? '1;34' : '0;36')
    super
    print @display.color('0')
  end
end
end
end
