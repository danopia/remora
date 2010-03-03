module Remora
module UI
class Display
  attr_accessor :width, :height, :client, :panes, :buffer, :dirty, :active_pane, :active_control
  
  def initialize client
    @client = client
    @panes = {}
    @dirty = true
    prepare_modes
    
    size = terminal_size
    @width = size[1]
    @height = size[0]
  end
  
  def pane name, *args, &blck
    @panes[name] = Pane.new(self, *args, &blck)
  end
  
  def alert name, *args, &blck
    @panes[name] = Alert.new(self, *args, &blck)
  end
  
  def place row, col, text
    print "\e[#{row.to_i};#{col.to_i}H#{text}"
  end
  def color codes
    "\e[#{codes}m"
  end
  
  def cursor=(show)
    print "\e[?25h" if show
    print "\e[?25l" unless show
    $stdout.flush
  end
  
  def linedrawing=(toggle)
    print "\x0E\e)0" if toggle
    print "\x0F" unless toggle
  end
  
  def dirty! pane=nil
    if pane
      @panes[pane].dirty!
    else
      @dirty = true
    end
  end
  
  def [] pane, control=nil
    if control
      @panes[pane].controls[control]
    else
      @panes[pane]
    end
  end
  
  def focus *path
    self.active_control = self[*path]
  end
  
  def handle
    handle_stdin
    
    size = terminal_size
    if @width != size[1] || @height != size[0]
      @width = size[1]
      @height = size[0]
      dirty!
    end
    
    if @dirty
      redraw
      @dirty = false
    else
      panes = @panes.values.select {|pane| pane.dirty? && pane.visible? }
      redraw panes if panes.any?
    end
    @panes.each_value {|pane| pane.dirty = false }
  end
  
  def redraw panes=nil
    print "\e[H\e[J" unless panes # clear all and go home
    
    panes ||= @panes.values
    panes.each {|pane| pane.redraw if pane.visible? }
    @panes.each_value {|pane| pane.draw_title if pane.visible? }
    print "\e[u"
    
    $stdout.flush
  end
  
  def active_control= control
    @active_pane = control.pane
    @active_control = control
  end
  
  def cycle_controls
    index = @active_pane.controls.keys.index @active_pane.controls.key(@active_control)
    begin
      index += 1
      index = 0 if index >= @active_pane.controls.size
    end until @active_pane.controls[@active_pane.controls.keys[index]].respond_to? :handle_char
    old = @active_control
    @active_control = @active_pane.controls[@active_pane.controls.keys[index]]
    old.redraw
    @active_control.redraw
  end
  
  # \e[Z      shift-tab
  #
  # \e[A      up
  # \e[B      down
  # \e[C      right
  # \e[D      left
  # \e[E      middle (5 with numlock off)
  #
  # \e[2~  \e[3~  \eOH \eOF \e[5~ \e[6~
  # insert delete home end  pgup  pgdown
  #
  #  ----  \eOQ   \eOR   \eOS
  #   F1     F2     F3     F4
  #
  # \e[15~ \e[17~ \e[18~ \e[19~
  #   F5     F6     F7     F8
  #
  # \e[20~ ------ ------ \e[24~
  #   F9     F10    F11    F12
  #
  # alt-anything => \e*KEY* (same as Esc, key)
  # alt-[ would become \e[ which is an ANSI escape
  #
  # ctrl-stuff becomes weird stuff, i.e. ctrl-space = \x00, ctrl-a = \x01, ctrl-b = \x02
  #
  # super is not sent?
  #
  def handle_stdin
    $stdin.read_nonblock(1024).each_char do |chr|
      if chr == "\t"
        cycle_controls
      else
        @active_control.handle_char chr if @active_control
      end
    end
    
    $stdout.flush
    
  rescue Errno::EAGAIN
  rescue EOFError
  end
  
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
    self.cursor = false
  end
  def undo_modes # restore previous terminal mode
    $stdout.ioctl(TCSETS, @old_modes.pack("IIIICCA*"))
    print "\e[2J\e[H" # clear all and go home
    self.linedrawing = false
    self.cursor = true # show the mouse
  end
end
end
end
