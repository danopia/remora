module Remora
module UI
class Pane
  attr_accessor :display, :x1, :y1, :x2, :y2, :title, :controls, :handler, :dirty, :visible
  
  def initialize display, x1, y1, x2, y2, title, controls={}, &blck
    @display = display
    @x1, @y1 = x1, y1
    @x2, @y2 = x2, y2
    @title, @controls = title, controls
    @dirty = false
    @visible = true
    
    instance_eval &blck if blck
  end
  
  def [] control
    @controls[control]
  end
  
  alias dirty? dirty
  def dirty!
    @dirty = true
  end
  
  alias visible? visible
  def show!; @visible = true; end
  def hide!; @visible = false; end
  
  def yank_values
    vals = {}
    @controls.each_pair do |key, control|
      next unless control.respond_to? :value
      vals[key] = control.value
      control.value = ''
    end
    vals
  end
  
  def on_submit &blck
    @handler = blck
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
    draw_title
  end
  
  def draw_contents
    controls.each_value do |control|
      control.redraw
    end
  end
  
  def control_at x, y
    @controls.values.each do |control|
      return control if (control.x1..control.x2).include?(x) && (control.y1..control.y2).include?(y)
    end
    nil
  end
  
  def handle_click button, modifiers, x, y
    control = control_at x, y
    control.focus! if button == :left
    if control && control.respond_to?(:handle_click)
      control.handle_click button, modifiers, x, y
    end
    control.redraw
  end

  def draw_frame
    linebar = 'q' * (width - 1)
    fillerbar = ' ' * (width - 1)

    @display.linedrawing = true
    print @display.color('0;2')
    
    @display.place y1, x1, "n#{linebar}n"
    @display.place y2, x1, "n#{linebar}n"
    #~ @display.place y1, x1, "l#{topbar}k"
    #~ @display.place y2, x1, "m#{bottombar}j"

    (y1 + 1).upto y2 - 1 do |row|
      @display.place row, x1, "x#{fillerbar}x"
    end
    
    @display.linedrawing = false
    print @display.color('0')
  end

  def draw_title
    title = " * #{@title} * "
    left = (((width - 1).to_f / 2) - (title.size.to_f / 2)).to_i

    if title.size >= width
      title = @title[0, width - 3]
      left = 0
    end
    
    print @display.color('1;34')
    @display.place y1, x1 + 1 + left, title
    print @display.color('0')
  end
end
end
end
