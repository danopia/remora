module Remora
module UI
class Label < Control
  attr_accessor :alignment, :text
  
  def initialize *args
    @alignment = :left
    @text = 'Label'
    super
  end
  
  def align direction
    @alignment = direction
  end
  
  def align_text text
    case @alignment
      when :center
        text.center width
      when :right
        text.rjust width
      else
        text.ljust width
    end
  end
  
  def redraw
    if text.empty?
      @display.place y1, x1, ' ' * width
      return
    end
    
    row = y1
    text.each_line do |line|
      line.chomp!
      length = line.size
      offset = 0
      while offset < width || offset == 0
        @display.place row, x1, align_text(line[offset, width])
        row += 1
        offset += width
        return if row >= y2
      end
    end
  end
end
end
end
