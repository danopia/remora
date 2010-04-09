module Remora
module UI
class ANSIDriver
  attr_reader :width, :height
  
  def initialize
    prepare_modes
    
    @height, @width = terminal_size
  end
  
  def flush
    $stdout.flush
  end
  
  def put row, col, text
    text.each_line do |line|
      print "\e[#{row.to_i};#{col.to_i}H#{line}"
      row += 1
    end
  end
  
  def color codes
    "\e[#{codes}m"
  end
  
  def cursor=(show)
    print "\e[?25" + (show ? 'h' : 'l')
  end
  
  def linedrawing=(toggle)
    print(toggle ? "\x0E\e)0" : "\x0F")
  end
  
  def resized?
    size = terminal_size
    
    return false if [@height, @width] == size
    
    @height, @width = size
    true
  end
  
  def clear; print "\e[H"; end
  def cursor_to_home; print "\e[J"; end
  
  def save_cursor; print "\e[s"; end
  def restore_cursor; print "\e[u"; end
  def set_cursor row, col; put row, col, "\e[s"; end
  
  def set_title title; print "\e]2;#{title}\007"; end
  
  #~ BUTTONS = {
    #~ 0 => :left,
    #~ 1 => :middle,
    #~ 2 => :right,
    #~ 3 => :release,
    #~ 64 => :scrollup,
    #~ 65 => :scrolldown
  #~ }
  #~ 
  #~ # alt-anything => \e*KEY* (same as Esc, key)
  #~ # alt-[ would become \e[ which is an ANSI escape
  #~ #
  #~ # ctrl-stuff becomes weird stuff, i.e. ctrl-space = \x00, ctrl-a = \x01, ctrl-b = \x02
  #~ #
  #~ # super is not sent?
  #~ def handle_stdin
    #~ @escapes ||= 0
    #~ @ebuff ||= ''
    #~ 
    #~ $stdin.read_nonblock(1024).each_char do |chr|
    #~ 
      #~ if @escapes == 0
        #~ if chr == "\e"
          #~ @escapes = 1
        #~ elsif chr == "\t"
          #~ cycle_controls
        #~ elsif chr == "\177"
          #~ route_key :backspace
        #~ else
          #~ route_key chr
        #~ end
        #~ 
      #~ elsif @escapes == 1 && chr == '['
        #~ @escapes = 2
      #~ elsif @escapes == 1 && chr == 'O'
        #~ @escapes = 5
        #~ 
      #~ elsif @escapes == 2
        #~ if chr == 'A'
          #~ route_key :up
        #~ elsif chr == 'B'
          #~ route_key :down
        #~ elsif chr == 'C'
          #~ route_key :right
        #~ elsif chr == 'D'
          #~ route_key :left
        #~ elsif chr == 'E'
          #~ route_key :center
        #~ elsif chr == 'Z'
          #~ cycle_controls_back
        #~ else
          #~ @ebuff = chr
          #~ @escapes = 3
        #~ end
        #~ @escapes = 0 if @escapes == 2
        #~ 
      #~ elsif @escapes == 3
        #~ if chr == '~' && @ebuff.to_i.to_s == @ebuff
          #~ route_key case @ebuff.to_i
            #~ when 2; :insert
            #~ when 3; :delete
            #~ when 5; :pageup
            #~ when 6; :pagedown
            #~ when 15; :f5
            #~ when 17; :f6
            #~ when 18; :f7
            #~ when 19; :f8
            #~ when 20; :f9
            #~ when 24; :f12
            #~ else; raise @ebuff.inspect
          #~ end
        #~ elsif @ebuff[0,1] == 'M' && @ebuff.size == 3
          #~ @ebuff += chr
          #~ info, x, y = @ebuff.unpack('xCCC').map{|i| i - 32}
          #~ modifiers = []
          #~ modifiers << :shift if info & 4 == 4
          #~ modifiers << :meta if info & 8 == 8
          #~ modifiers << :control if info & 16 == 16
          #~ pane = pane_at(x, y)
          #~ 
          #~ unless modal && modal != pane
            #~ pane.handle_click BUTTONS[info & 71], modifiers, x, y if pane
          #~ end
        #~ elsif @ebuff.size > 10
          #~ raise "long ebuff #{@ebuff.inspect} - #{chr.inspect}"
        #~ else
          #~ @ebuff += chr
          #~ @escapes = 4
        #~ end
        #~ @escapes = 0 if @escapes == 3
        #~ @escapes = 3 if @escapes == 4
        #~ @ebuff = '' if @escapes == 0
        #~ 
      #~ elsif @escapes == 5
        #~ if chr == 'H'
          #~ route_key :home
        #~ elsif chr == 'F'
          #~ route_key :end
        #~ elsif chr == 'Q'
          #~ route_key :f2
        #~ elsif chr == 'R'
          #~ route_key :f3
        #~ elsif chr == 'S'
          #~ route_key :f4
        #~ else
          #~ raise "escape 5 #{chr.inspect}"
        #~ end
        #~ @escapes = 0
        #~ 
      #~ else
        #~ @escapes = 0
      #~ end
    #~ end
    #~ 
    #~ $stdout.flush
    #~ 
  #~ rescue Errno::EAGAIN
  #~ rescue EOFError
  #~ end
  
  
  ######################################
  # this is all copied from cashreg :P #
  ######################################

  # yay grep
  TIOCGWINSZ = 0x5413
  TCGETS = 0x5401
  TCSETS = 0x5402
  ECHO   = 8 # 0000010
  ICANON = 2 # 0000002

  # thanks google for all of this
  def terminal_size
    rows, cols = 25, 80
    buf = [0, 0, 0, 0].pack("SSSS")
    if $stdout.ioctl(TIOCGWINSZ, buf) >= 0 then
      rows, cols, row_pixels, col_pixels = buf.unpack("SSSS")
    end
    return [rows, cols]
  end

  # had to convert these from C... fun
  def prepare_modes
    buf = [0, 0, 0, 0, 0, 0, ''].pack("IIIICCA*")
    $stdout.ioctl(TCGETS, buf)
    @old_modes = buf.unpack("IIIICCA*")
    new_modes = @old_modes.clone
    new_modes[3] &= ~ECHO # echo off
    new_modes[3] &= ~ICANON # one char @ a time
    $stdout.ioctl(TCSETS, new_modes.pack("IIIICCA*"))
    print "\e[2J" # clear screen
    print "\e[H" # go home
    print "\e[?47h" # kick xterm into the alt screen
    print "\e[?1000h" # kindly ask for mouse positions to make up for it
    self.cursor = false
    flush
  end
  
  def undo_modes # restore previous terminal mode
    $stdout.ioctl(TCSETS, @old_modes.pack("IIIICCA*"))
    print "\e[2J" # clear screen
    print "\e[H" # go home
    print "\e[?47l" # kick xterm back into the normal screen
    print "\e[?1000l" # turn off mouse reporting
    self.linedrawing = false
    self.cursor = true # show the mouse
    flush
  end
end
end
end
