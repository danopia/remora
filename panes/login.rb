module Remora
class LoginPane < Luck::Alert
  def initialize display
    super display, 30, 8, 'Login to Grooveshark'
    
    hide!
    
    control :user, Luck::TextBox, 3, 2, -3, 2 do
      self.label = 'Username'
      self.text = ''
    end
    control :pass, Luck::TextBox, 3, 4, -3, 4 do
      self.label = 'Password'
      self.text = ''
      self.mask = '*'
    end
    
    control :submit, Luck::Button, 5, 6, 14, 6 do
      self.text = 'Login'
      self.alignment = :center
    end
    control :cancel, Luck::Button, 15, 6, 25, 6 do
      self.text = 'Cancel'
      self.alignment = :center
      
      on_submit do
        display[:login].yank_values # clear the boxes
        display[:login].hide!
        display.focus :main, :search
        display.dirty!
      end
    end
      
    on_submit do
      creds = yank_values
      
      display[:login].hide!
      display.dirty!
      
      $client.login creds[:user], creds[:pass]
      
      $results = $client.user.favorites
      display[:main, :results].data = $results
      display[:main].title = "Your Favorites"
      
      display.focus :main, :search
      display.dirty!
    end
  end
end
end
