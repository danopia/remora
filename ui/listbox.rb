module Remora
module UI
class ListBox < Control
  attr_accessor :data, :numbering, :hanging_indent
  
  def on_submit &blck
    @handler = blck
  end
  
  def handler
    @handler || @pane.handler
  end
  
  def initialize *args
    @data = []
    @hanging_indent = 0
    @offset = 0
    super
  end
  
  def number!
    @numbering = true
    @hanging_indent = 4
  end
  
  def fit_data
    lines = 0
    items = 0
    
    data[@offset, height].each do |line|
      _height = line_height(line)
      if _height + lines > height
        break
      else
        lines += _height
        items += 1
      end
    end
    
    [lines, items]
  end
  
  def line_height line
    lines = 0
    
    line = line.to_s
    line = "##. #{line}" if @numbering
    length = line.size
    return 1 if length < 1
    offset = 0
    while offset < length
      lines += 1
      offset += width - ((offset > 0) ? @hanging_indent : 0)
    end
    
    lines
  end
  
  def fit_data_back
    lines = 0
    items = 0
    
    data[([@offset - height,0].max)..([@offset,0].max)].reverse.each do |line|
      _height = line_height(line)
      if _height + lines >= height
        break
      else
        lines += _height
        items += 1
      end
    end
    
    [lines, items]
  end
  
  def redraw
    row = y1
    data[@offset, height].each_with_index do |line, index|
      line = line.to_s
      line = "#{(index + @offset + 1).to_s.rjust 2}. #{line}" if @numbering
      length = line.size
      offset = 0
      while offset < length || offset == 0
        @display.place row, x1, ((' ' * ((offset > 0) ? @hanging_indent : 0)) + line[offset, width - ((offset > 0) ? @hanging_indent : 0)]).ljust(width, ' ')
        row += 1
        offset += width - ((offset > 0) ? @hanging_indent : 0)
        break if row >= y2
      end
      break if row >= y2
    end
    
    until row >= y2
      @display.place row, x1, ' ' * width
      row += 1
    end
  end
  
  def handle_char char
    if char == "\n"
      handler.call self, nil if handler
    elsif char == :up
      @offset -= 1 if @offset > 0
    elsif char == :down
      @offset += 1 if @offset < @data.size - 1
    elsif char == :pageup
      @offset = [0, @offset - fit_data_back[1]].max
    elsif char == :pagedown
      @offset = [@data.size - 1, @offset + fit_data[1]].min
    end
    redraw
  end
end
end
end
