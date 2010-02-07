module Remora
class UI
  attr_accessor :width, :height, :client, :panes, :buffer, :mode
  
  def initialize client
    @client = client
    @panes = {}
    @buffer = ''
    prepare_modes
    get_term_size
    
    panes[:queue] = Remora::UIPane.new self, 1, 1, 20, -1, 'Queue'
    panes[:main] = Remora::UIPane.new self, 20, 1, -1, -5, 'Search Results'
    panes[:np] = Remora::UIPane.new self, 20, -5, -1, -1, 'Now Playing'
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
  
  def redraw
    handle_stdin
  
    get_term_size
    print "\e[H\e[J" # clear all and go home
    
    #~ @panes.each_value do |pane|
      #~ pane.redraw
    #~ end
    print "\e[s"
    panes[:queue].redraw
    panes[:main].redraw
    panes[:np].redraw
    print "\e[u"
    place 2, 22, @buffer
    
    $stdout.flush
  end
  
  def handle_stdin
    $stdin.read_nonblock(1024).each_char do |chr|
      if chr == "\n"
	next if @buffer.empty?
	
	if @buffer.to_i.to_s == @buffer && @results
	  index = @buffer.to_i - 1
	  next if index < 0 || index > @results.size
	  
	  song = @results[index]
	  @client.queue << song
	  
	  unless @client.now_playing
	    Thread.new do
	      @client.queue.play_radio
	    end
	  end
	  
	  @buffer = ''
	  panes[:main].data[0] = @buffer.empty? ? (@search || '') : ''
	  self.cursor = false
	else
	  @search = @buffer
	  @results = @client.search_songs(@search)['Return']
	  panes[:main].data = @results.map do |result|
	    "#{(@results.index(result)+1).to_s.rjust 2}) #{result['Name']} - #{result['ArtistName']} - #{result['AlbumName']}"
	  end
	  panes[:main].data.unshift @search
	  panes[:main].title = "Search Results for #{@search}"

	  @buffer = ''
	  self.cursor = false
	end
      else
	@buffer << chr
	@buffer.gsub!(/.\177/, '')
	@buffer.gsub!("\177", '')
	panes[:main].data[0] = @buffer.empty? ? (@search || '') : ''
	self.cursor = !(@buffer.empty?)
      end
    end
  rescue Errno::EAGAIN
  rescue EOFError
  end
  
  def get_term_size
    data = terminal_size
    @width = data[1]
    @height = data[0]
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

class UIPane
  attr_accessor :ui, :x1, :y1, :x2, :y2, :title, :data
  
  def initialize ui, x1, y1, x2, y2, title, data=[]
    @ui = ui
    @x1, @y1 = x1, y1
    @x2, @y2 = x2, y2
    @title, @data = title, data
  end
  
  def x1
    (@x1 < 0) ? (@ui.width + @x1 + 1) : @x1
  end
  def y1
    (@y1 < 0) ? (@ui.height + @y1 + 1) : @y1
  end
  
  def x2
    (@x2 < 0) ? (@ui.width + @x2 + 1) : @x2
  end
  def y2
    (@y2 < 0) ? (@ui.height + @y2 + 1) : @y2
  end
  
  def width
    x2 - @x1
  end
  def height
    y2 - @y1
  end
  
  def redraw
    draw_frame
    row = y1 + 1
    data.first(height).each do |line|
      length = line.to_s.size
      offset = 0
      while offset <= length
	@ui.place row, x1+((offset > 0) ? 6 : 2), line.to_s[offset, width - 3]
	row += 1
	offset += width - 3
      end
      break if row >= y2
    end
    
    $stdout.flush
  end
  
  def topbar
    title = " * #{@title} * "
    left = (((width - 1).to_f / 2) - (title.size.to_f / 2)).to_i

    title_colored = "#{@ui.color '1;34'}#{title}#{@ui.color '0;2'}"
    ('-' * left) + title_colored + ('-' * (width - 1 - title.size - left))
  end

  def draw_frame
    bottombar = '-' * (width - 1)
    fillerbar = ' ' * (width - 1)

    print @ui.color('0;2')
    @ui.place y1, x1, "+#{topbar}+"
    @ui.place y2, x1, "+#{bottombar}+"

    (y1 + 1).upto y2 - 1 do |row|
      @ui.place row, x1, "|#{fillerbar}|"
    end
    print @ui.color('0')
  end
end
end

#~ puts "Enter a search query:"
#~ query = gets.chomp
#~ puts
#~ puts "Searching for \"#{query}\":"
#~ results = client.search_songs(query)['Return']
#~ results.each do |result|
  #~ puts "#{results.index result} - #{result['Name']} - #{result['ArtistName']} - #{result['AlbumName']}"
#~ end

#~ ui = Remora::UI.new nil
#~ 
#~ ui.panes[:queue].data = ['1. Song One', '2. Another Song']
#~ 
#~ trap 'INT' do
  #~ ui.undo_modes
  #~ exit
#~ end
#~ 
#~ while true
  #~ 
  #~ ui.redraw
  #~ sleep 0.1
#~ end
