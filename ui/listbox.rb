module Remora
module UI
class ListBox < Control
  attr_accessor :data, :numbering, :hanging_indent
  
  def initialize *args
    @data = []
    @hanging_indent = 0
    super
  end
  
  def number!
    @numbering = true
    @hanging_indent = 4
  end
  
  def redraw
    row = y1
    data.first(height).each_with_index do |line, index|
      line = line.to_s
      line = "#{(index + 1).to_s.rjust 2}. #{line}" if @numbering
      length = line.size
      offset = 0
      while offset < length || offset == 0
        @display.place row, x1 + ((offset > 0) ? @hanging_indent : 0), line[offset, width - ((offset > 0) ? @hanging_indent : 0)]
        row += 1
        offset += width - ((offset > 0) ? @hanging_indent : 0)
        break if row >= y2
      end
      break if row >= y2
    end
  end
end
end
end
