#~ panes[:queue] = Remora::UIPane.new self, 1, 1, 20, -1, 'Queue'
#~ panes[:main] = Remora::UIPane.new self, 20, 1, -1, -5, 'Search Results'
#~ panes[:np] = Remora::UIPane.new self, 20, -5, -1, -1, 'Now Playing'
#~ 
  #~ def handle_stdin
    #~ $stdin.read_nonblock(1024).each_char do |chr|
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
    #~ end
  #~ rescue Errno::EAGAIN
  #~ rescue EOFError
  #~ end

require File.join(File.dirname(__FILE__), 'ui', 'display')
require File.join(File.dirname(__FILE__), 'ui', 'pane')
require File.join(File.dirname(__FILE__), 'ui', 'control')
require File.join(File.dirname(__FILE__), 'ui', 'listbox')
#require File.join(File.dirname(__FILE__), 'ui', 'textbox')

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

begin
  display = Remora::UI::Display.new nil

  trap 'INT' do
    display.undo_modes
    exit
  end

  display.pane :queue, 1, 1, 20, -1, 'Queue' do
    control :songs, Remora::UI::ListBox, 1, 1, -1, -1 do
      data << 'Hello!'
      data << 'This is a listbox.'
      data << 'This is a very long entry.'
      data << ''
      data << '#' * width
      data << '#' * width
      data << '#' * width
    end
  end

  display.pane :main, 20, 1, -1, -1, 'Search results' do
    control :results, Remora::UI::ListBox, 1, 1, -1, -1 do
      self.number!
      
      data << 'Song 1 - Artist 1 - Album 1'
      data << 'Song 2 - Artist 2 - Album 2'
      data << 'Another song by another artist'
      data << 'Another song, but it might be by one of the above artists for all that you know! :D'
      data << 'Yet another song.'
      data << 5
      data << 'LYAH!'
      data << ''
      data << 'This is going to be a list of songs.'
      data << 'It could also be now if I list some.'
      data << ''
      data << 'White & Nerdy - Weird Al'
      data << 'I Wanna Talk About Me - Toby Keith'
      data << 'Paradise City - Guns n\' Roses'
    end
  end

  display.redraw while sleep 1

rescue => ex
  display.undo_modes
  puts ex.class, ex.message, ex.backtrace
  exit
end
