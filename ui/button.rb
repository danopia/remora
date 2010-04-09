module Remora
module UI
class Button < Label
  attr_accessor :handler
  
  def on_submit &blck
    @handler = blck
  end
  
  def handle_char char
    if char == "\n"
      handler.call self, @text if handler
    end
    #redraw
  end
  
  def handle_click button, modifiers, x, y
    handler.call self, @text if button == :left && handler
  end
  
  def text
    "[ #{@text} ]"
  end
  
  def handler
    @handler || @pane.handler
  end
  
  def redraw
    @display.driver.cursor = false
    print @display.color(@display.active_control == self ? '1;34' : '0;36')
    super
    print @display.color('0')
  end
end
end
end
