module Remora
class SongInfoPane < Luck::Alert
  def initialize display
    super display, 60, 15, 'Song Info'
    
    hide!
    
    control :details, Luck::ListBox, 3, 2, -3, -4
    
    control :queue, Luck::Button, 20, -2, 30, -2 do
      self.text = 'Queue'
      self.alignment = :center
      
      on_submit do
        display[:songinfo].hide!
        display.dirty!
        
        #~ $results = client.user.favorites
        #~ display[:main, :results].data = $results
        #~ display[:main].title = "Your Favorites"
        
        display.focus :main, :search
        display.dirty!
      end
    end
    
    control :close, Luck::Button, 31, -2, 41, -2 do
      self.text = 'Close'
      self.alignment = :center
    end
      
    on_submit do
      display[:songinfo].hide!
      display.focus :main, :search
      display.dirty!
    end
  end
end
end
