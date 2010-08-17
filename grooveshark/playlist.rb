module GrooveShark
class Playlist
  include DRbUndumped
  attr_reader :id, :name, :about, :picture, :userid, :username, :songs

  def self.by_user client, user_id
    lists = client.request_more('userGetPlaylists', :userID => user_id)['Playlists']
    
    lists.map do |info|
      Playlist.new client, info, user_id
    end
  end
  
  def self.from_id client, id
    hash = client.request_more('getPlaylistByID', :playlistID => id)
    Playlist.new client, hash
  end
  
  def self.load_from_id client, id
    list = from_id client, id
    list.load_songs
    list
  end
  
  def self.load_from_hash client, hash, user_id=nil
    list = Playlist.new client, hash, user_id
    list.load_songs
    list
  end


  def initialize client, hash=nil, user_id=nil
    if hash
      @id = hash['PlaylistID']
      @name = hash['Name']
      @about = hash['About']
      @picture = hash['Picture']
      @userid = hash['UserID'] || user_id
      @username = hash['Username']
    end
    
    @songs = []
  end
  
  def load_songs
    @songs = @client.request_more('playlistGetSongs', :playlistID => @id)['Songs']
    @songs.map! {|song| Song.new song }
  end
end
end
