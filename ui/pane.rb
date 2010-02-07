module Remora
module UI
class Pane
  attr_accessor :display, :x1, :y1, :x2, :y2, :title, :controls
  
  def initialize display, x1, y1, x2, y2, title, controls={}, &blck
    @display = display
    @x1, @y1 = x1, y1
    @x2, @y2 = x2, y2
    @title, @controls = title, controls
    
    instance_eval &blck if blck
  end
  
  def control name, type, *args, &blck
    @controls[name] = type.new(self, *args, &blck)
  end
  
  def x1
    (@x1 < 0) ? (@display.width + @x1 + 1) : @x1
  end
  def y1
    (@y1 < 0) ? (@display.height + @y1 + 1) : @y1
  end
  
  def x2
    (@x2 < 0) ? (@display.width + @x2 + 1) : @x2
  end
  def y2
    (@y2 < 0) ? (@display.height + @y2 + 1) : @y2
  end
  
  def width
    x2 - x1
  end
  def height
    y2 - y1
  end
  
  def redraw
    draw_frame
    draw_contents
  end
  
  def draw_contents
    controls.each_value do |control|
      control.redraw
    end
  end
  
  def topbar
    title = " * #{@title} * "
    left = (((width - 1).to_f / 2) - (title.size.to_f / 2)).to_i

    if title.size >= width
      "#{@display.color '1;34'} #{@title[0, width - 3].center(width - 3)} #{@display.color '0;2'}"
    else
      title_colored = "#{@display.color '1;34'}#{title}#{@display.color '0;2'}"
      ('-' * left) + title_colored + ('-' * (width - 1 - title.size - left))
    end
  end

  def draw_frame
    bottombar = '-' * (width - 1)
    fillerbar = ' ' * (width - 1)

    print @display.color('0;2')
    @display.place y1, x1, "+#{topbar}+"
    @display.place y2, x1, "+#{bottombar}+"

    (y1 + 1).upto y2 - 1 do |row|
      @display.place row, x1, "|#{fillerbar}|"
    end
    print @display.color('0')
  end
end
end
end
