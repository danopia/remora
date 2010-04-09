module Remora
module UI
class TextBox < Label
  attr_accessor :multiline, :handler, :label, :mask, :index
  
  def initialize *args
    @label = ''
    @text = 'Input box'
    @index = 0
    
    super
  end
  
  def redraw
    super
    
    case @alignment
      when :center
        text.center width
      when :right
        text.rjust width
      else
        @display.driver.set_cursor y1, x1 + text.size - @text.size + @index if @display.active_control == self
    end
    @display.driver.cursor = true if @display.active_control == self
  end
  
  def on_submit &blck
    @handler = blck
  end
  
  def value= val
    @text = val
    @index = @text.size if @index > @text.size
  end
  def value
    @text
  end
  
  def text
    text = @mask ? (@mask * value.size) : value
    text = "#{label}: #{text}" unless label.empty?
    text
  end
  
  def handler
    @handler || @pane.handler
  end
  
  def handle_char char
    if char == "\n" && !@multiline
      handler.call self, @text if handler
      self.value = ''
    elsif char == :backspace
      if @index > 0
        @index -= 1
        @text.slice! @index, 1
      end
    elsif char == :delete
      if @index < @text.size
        @text.slice! @index, 1
      end
    elsif char == :left
      @index -= 1 if @index > 0
    elsif char == :right
      @index += 1 if @index < @text.size
    elsif char == :home
      @index = 0
    elsif char == :end
      @index = @text.size
    elsif char.is_a? String
      @text.insert @index, char
      @index += 1
    end
    redraw
  end
end

class CommandBox < TextBox
  def command?
    @text[0,1] == '/'
  end
  
  def label
    command? ? 'Command' : @label
  end
  
  def value
    command? ? super[1..-1] : super
  end
end
end
end
