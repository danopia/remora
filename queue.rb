module GrooveShark
class Queue
  attr_accessor :songs, :next_index, :id, :client
  
  def initialize client
    @client = client
    @id = @client.request_service 'initiateQueueEx'
    
    @songs = {}
    @next_index = 1
  end
  
  def << song
    @client.request_service 'addSongsToQueueExt', {
      'songIDsArtistIDs' => [{
        'artistID' => song['ArtistsID'],
        'songID' => song['SongID'],
        'songQueueSongID' => @next_index,
        'source' => 'user',
      }],
      'songQueueID' => @id
    }
    @songs[@next_index] = song
    @next_index += 1
    @next_index - 1
  end
  
  def delete song
    delete_at @songs.index(song)
  end
  def delete_at index
    @client.request_service 'removeSongsFromQueueExte', {
      'songQueueSongIDs' => [index],
      'userRemoved' => true,
      'songQueueID' => @id
    }
    @songs.delete index
  end
  
  def [] index
    @songs[index]
  end

  def play index
    @client.play @songs[index]
  end
end
end
