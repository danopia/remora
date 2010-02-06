module Remora
class UI
  attr_accessor :width, :height, :client
  
  def initialize client
    @client = client
  end
  
  def get_term_size
    @width = `tput cols`.to_i - 1
    @height = `tput lines`.to_i - 1
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
    get_term_size
    
    draw_frame 1, 1, 30, @height, 'Queue'
    row = 2
    @client.queue.songs.each_value do |song|
      print color((@client.now_playing == song) ? '1;32' : '1;31')
      place row, 2, song['SongName'] || song['Name']
      row += 1
    end
    
    $stdout.flush
  end
  
  def topbar width, text
		title = " * #{text} * "
		left = (((width - 1).to_f / 2) - (title.size.to_f / 2)).to_i
		
		title_colored = "#{color '1;34'}#{title}#{color '0;2'}"
		('-' * left) + title_colored + ('-' * (width - 1 - title.size - left))
	end
  
  def draw_frame x, y, width, height, title
    y2 = y + height
    
		bottombar = '-' * (width - 1)
		fillerbar = ' ' * (width - 1)
		
		print color('0;2')
		place y, x, "+#{topbar width, title}+"
		place y2, x, "+#{bottombar}+"
		
		(y + 1).upto y2 - 1 do |row|
			place row, x, "|#{fillerbar}|"
		end
		print color('0')
		
		$stdout.flush
	end
end
end
