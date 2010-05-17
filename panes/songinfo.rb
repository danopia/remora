module Remora
class SongInfoPane < Luck::Alert
  attr_reader :song
  
  def initialize display, song=nil
    super display, 60, 16, 'Song Info'
    
    hide!
    
    control :details, Luck::ListBox, 3, 2, -3, -4
    
    control :queue, Luck::Button, 20, -2, 30, -2 do
      self.text = 'Queue'
      self.alignment = :center
      
      on_submit do
        display.client.queue << song
        
        unless display.client.now_playing
          Thread.new do
            begin
              display.client.queue.play_radio
            rescue => ex
              display.close
              puts ex.class, ex.message, ex.backtrace
              exit
            end
          end
        end
        
        display.panes.delete :songinfo
        display.modal = nil
        display.focus :main, :search
        display.dirty!
      end
    end
    
    control :close, Luck::Button, 31, -2, 41, -2 do
      self.text = 'Close'
      self.alignment = :center
    end
      
    on_submit do
      display.panes.delete :songinfo
      display.modal = nil
      display.focus :main, :search
      display.dirty!
    end
    
    self.song = song if song
  end
  
  def song= song
    @song = song
    
    list = controls[:details].data = []
    
    list << "Title: #{song.title}"
    list << "Album: #{song.album}"
    list << "Artist: #{song.artist}"
    
    list << ''
    
    minutes = song.duration.to_i / 60
    seconds = song.duration.to_i - minutes*60
    list << "Length: #{format '%d:%02d', minutes, seconds.to_i}"
    
    list << "Track: #{song.data['TrackNum']}"
    list << "Year: #{song.data['Year']}"
    
    list << ''
    
    list << "Song plays: #{song.data['SongPlays']}"
    list << "Artist plays: #{song.data['ArtistPlays']}"
    list << "Popularity: #{song.data['Popularity']}"
  end
end
end
