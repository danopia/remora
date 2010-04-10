module Remora
module UI
class ListBox < Control
  attr_accessor :data, :numbering, :hanging_indent, :offset, :index, :lastclick
  
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
    @index = 0
    @lastclick = Time.at 0
    super
  end
  
  def number!
    @numbering = true
    @hanging_indent = 4
  end
  
  def fit_data offset=nil
    lines = 0
    items = 0
    
    data[offset || @offset, height].each do |line|
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
  
  def fit_data_back offset=nil
    lines = -1
    items = 0
    
    offset ||= @offset
    data[([offset - height,0].max)..([offset,0].max)].reverse.each do |line|
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
    @display.driver.cursor = false if @display.active_control == self
    
    row = y1
    return unless data
    data[@offset, height].each_with_index do |line, index|
      line = line.to_s
      number = index + @offset + 1
      line = "#{number.to_s.rjust 2}. #{line}" if @numbering
      print @display.color '1;34' if number == @index + 1
      length = line.size
      offset = 0
      while offset < length || offset == 0
        @display.place row, x1, ((' ' * ((offset > 0) ? @hanging_indent : 0)) + line[offset, width - ((offset > 0) ? @hanging_indent : 0)]).ljust(width, ' ')
        row += 1
        offset += width - ((offset > 0) ? @hanging_indent : 0)
        if row >= y2
          print @display.color '0' if number == @index + 1
          break
        end
      end
      print @display.color '0' if number == @index + 1
      break if row >= y2
    end
    
    until row >= y2
      @display.place row, x1, ' ' * width
      row += 1
    end
  end
  
  def handle_char char
    if char == "\n"
      handler.call self, @data[@index] if handler
    elsif char == :up
      @index -= 1 if @index > 0
      @offset -= 1 if @offset > @index
    elsif char == :down
      if @index < @data.size - 1
        @index += 1 
        @offset += 1 if @offset + fit_data[1] <= @index
      end
    elsif char == :pageup
      @offset = [0, @offset - fit_data_back[1]].max
      @index = [@offset + fit_data[1] - 1, @index].min
    elsif char == :pagedown
      @offset = [@data.size - 1, @offset + fit_data[1]].min
      @offset = [@offset, @data.size - fit_data_back(@data.size)[1]].min
      @index = [@offset, @index].max
    end
    redraw
  end
  
  def handle_click button, modifiers, x, y
    if button == :scrollup
      @offset -= 1 if @offset > 0
      @index = [@offset + fit_data[1] - 1, @index].min
    elsif button == :scrolldown
      @offset += 1 if @offset < (@data.size - fit_data_back(@data.size)[1])
      @index = [@offset, @index].max
    
    elsif button == :left
      if Time.now - @lastclick < 0.5
        button = :double
      end
      @lastclick = Time.now
      
      previous = @index
      
      row = y1
      data[@offset, height].each_with_index do |line, index|
        _height = line_height(line)
        if _height + row > height
          break
        else
          row += _height
        end
        if row > y
          @index = index + @offset
          break
        end
      end
      
      handler.call self, @data[@index] if button == :double && previous == @index && handler
      
    end
    redraw
  end
end
end
end
