module Remora
module UI
class Alert < Pane
  attr_accessor :width, :height, :handler
  
  def initialize display, width, height, title, controls={}, &blck
    super display, nil, nil, nil, nil, title, controls, &blck
    
    @width, @height = width, height
  end
  
  def x1
    (@display.width / 2).to_i - (@width / 2).to_i
  end
  def y1
    (@display.height / 2).to_i - (@height / 2).to_i
  end
  
  def x2
    x1 + @width
  end
  def y2
    y1 + @height
  end
  
  def on_dismiss &blck
    @handler = blck
  end
  
  def handle_char char
    if char == "\n"
      @handler.call @text if @handler
    end
    #redraw
  end
end
end
end
