require File.join(File.dirname(__FILE__), 'ui')

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

  display.pane :main, 20, 1, -1, -5, 'Search results' do
    control :search, Remora::UI::CommandBox, 2, 1, -2, 1 do
      self.label = 'Search'
      self.text = ''
    end
    control :results, Remora::UI::ListBox, 1, 2, -1, -1 do
      number!
      
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

  display.pane :np, 20, -5, -1, -1, 'Now playing' do
    control :cue, Remora::UI::DoubleProgressBar, 2, 2, -2, 3 do
      template '==>->  '
      self.value = 0.7
      self.value2 = 0.2
    end
    control :song_name, Remora::UI::Label, 1, 1, -1, 1 do
      align :center
      self.text = 'Song - Artist - Album'
    end
  end

  display.alert :login, 30, 8, 'Login to Grooveshark' do
    display.active_control = control :user, Remora::UI::TextBox, 3, 2, -3, 2 do
      self.label = 'Username'
      self.text = ''
    end
    control :pass, Remora::UI::TextBox, 3, 4, -3, 4 do
      self.label = 'Password'
      self.text = ''
      self.mask = '*'
    end
    control :submit, Remora::UI::Button, 5, 6, 14, 6 do
      self.text = 'Login'
      self.alignment = :center
    end
    control :cancel, Remora::UI::Button, 15, 6, 25, 6 do
      self.text = 'Cancel'
      self.alignment = :center
      
      on_submit do
	# user canceled the action
      end
    end
      
    on_submit do
      yank_values
      display[:login].hide!
      display.active_control = display[:main, :search]
      display.dirty!
    end
  end

  display.handle while sleep 0.01

rescue => ex
  display.undo_modes
  puts ex.class, ex.message, ex.backtrace
  exit
end
