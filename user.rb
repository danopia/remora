module GrooveShark
class User
  include DRbUndumped
  attr_reader :id, :username, :premium, :data, :playlists, :favorites

  # {"userID":1839825,"username":"danopia","isPremium":"0",
  # "autoAutoplay":false,"authRealm":1,"favoritesLimit":500,
  # "librarySizeLimit":5000,"uploadsEnabled":1,"themeID":""}

  def self.login client, user, pass
    data = client.request_service 'authenticateUserEx', {:username => user, :password => pass}, true
    User.new client, data
  end
  
  def initialize client, hash=nil
    if hash
      @data = hash
      
      @id = hash['userID']
      @username = hash['username']
      @premium = hash['isPremium']
    end
    
    @client = client
    
    #@playlists = {}
    #@favorites = []
  end
  
  def playlists
    return @playlists if @playlists
    
    results = @client.request_more 'userGetPlaylists', :userID => @id
    @playlists = results['Playlists'].map {|list| Playlist.new @client, list, @id }
  end
  
  def favorites
    return @favorites if @favorites
    
    results = @client.request_more 'getFavorites', :ofWhat => 'Songs', :userID => @id
    @favorites = results.map {|song| Song.new song }
  end
end
end
