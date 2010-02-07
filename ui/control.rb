module Remora
module UI
class Control
  attr_accessor :pane, :display, :x1, :y1, :x2, :y2
  
  def initialize pane, x1, y1, x2, y2, &blck
    @pane = pane
    @display = pane.display
    @x1, @y1 = x1, y1
    @x2, @y2 = x2, y2
    
    instance_eval &blck if blck
  end
  
  def x1
    @pane.x1 + ((@x1 < 0) ? (@pane.width + @x1) : @x1)
  end
  def y1
    @pane.y1 + ((@y1 < 0) ? (@pane.height + @y1) : @y1)
  end
  
  def x2
    @pane.x1 + ((@x2 < 0) ? (@pane.width + @x2 + 1) : @x2)
  end
  def y2
    @pane.y1 + ((@y2 < 0) ? (@pane.height + @y2 + 1) : @y2)
  end
  
  def width
    x2 - x1
  end
  def height
    y2 - y1
  end
end
end
end
