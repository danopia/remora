module Remora
module UI
class Display
  attr_accessor :width, :height, :client, :panes, :buffer, :dirty, :active_control
  
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
  
  def dirty! pane=nil
    if pane && @dirty.is_a?(Array) && !(@dirty.include?(pane))
      @dirty << pane
    elsif pane && !@dirty
      @dirty = [pane]
    elsif !pane
      @dirty = true
    end
  end
  
  def handle
    handle_stdin
    
    size = terminal_size
    if @width != size[1] || @height != size[0]
      @width = size[1]
      @height = size[0]
      dirty!
    end
    
    return unless @dirty
    redraw @dirty
    @dirty = false
  end
  
  def redraw panes=true
    print "\e[H\e[J" if panes == true # clear all and go home
    self.cursor = active_control
    
    if panes == true
      panes = @panes.values
    else
      panes.map! {|key| @panes[key] }
    end
    
    panes.each do |pane|
      pane.redraw
    end
    print "\e[u"
    
    $stdout.flush
  end
  
  def handle_stdin
    $stdin.read_nonblock(1024).each_char do |chr|
      active_control.handle_char chr if active_control
      #~ if chr == "\n"
        #~ next if @buffer.empty?
        #~ 
        #~ if @buffer.to_i.to_s == @buffer && @results
          #~ index = @buffer.to_i - 1
          #~ next if index < 0 || index > @results.size
          #~ 
          #~ song = @results[index]
          #~ @client.queue << song
          #~ 
          #~ unless @client.now_playing
            #~ Thread.new do
              #~ @client.queue.play_radio
            #~ end
          #~ end
          #~ 
          #~ @buffer = ''
          #~ panes[:main].data[0] = @buffer.empty? ? (@search || '') : ''
          #~ self.cursor = false
        #~ else
          #~ @search = @buffer
          #~ @results = @client.search_songs(@search)['Return']
          #~ panes[:main].data = @results.map do |result|
            #~ "#{(@results.index(result)+1).to_s.rjust 2}) #{result['Name']} - #{result['ArtistName']} - #{result['AlbumName']}"
          #~ end
          #~ panes[:main].data.unshift @search
          #~ panes[:main].title = "Search Results for #{@search}"
#~ 
          #~ @buffer = ''
          #~ self.cursor = false
        #~ end
      #~ else
      #~ @buffer << chr
      #~ @buffer.gsub!(/.\177/, '')
      #~ @buffer.gsub!("\177", '')
      #~ panes[:main].data[0] = @buffer.empty? ? (@search || '') : ''
      #~ self.cursor = !(@buffer.empty?)
      #~ end
    end
    
    self.cursor = active_control
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
    self.cursor = true # show the mouse
  end
end
end
end
