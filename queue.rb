module GrooveShark
class Queue
  include DRbUndumped
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
        'source' => song['source'] || 'user',
      }],
      'songQueueID' => @id
    }
    @songs[@next_index] = song
    @next_index += 1
    #@next_index - 1
    
    @client.display.panes[:queue].controls[:songs].data = @songs.map do |(index, song)|
      song['SongName'] || song['Name']
    end
    @client.display.dirty! :queue
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
  
  def add_autoplay
    seeds = {}
    @songs.values.last(5).each {|song| seeds[song['ArtistID'].to_s] = 'p' }
    
    song = @client.request_service 'getSongForAutoplayExt', {
      'recentSongs' => @songs.values.last(5).map{|song| song['SongID'] },
      'secondaryArtistWeightModifier' => 0.9,
      'seedArtistWeightRange' => [70, 100],
      'maxDuration' => 1500,
      'minDuration' => 60,
      'weightModifierRange' => [-9, 9],
      'frowns' => [],
      'recentArtists' => @songs.values.last(5).map{|song| song['ArtistID'] },
      'seeds' => seeds,
      'songQueueID' => @id
    }
    #{"SongID":15220333,"AlbumID":1179236,"ArtistID":1587,"ArtistName":"Toby Keith","AlbumName":"Shock'n Y'all","CoverArtUrl":"http:\/\/beta.grooveshark.com\/static\/amazonart\/s11811240.jpg","EstimateDuration":263,"SponsoredAutoplayID":0,"SongName":"American Soldier","source":"recommended"}
    
    self << song if song
    song
  end
  
  def [] index
    @songs[index]
  end

  def play_radio
    @played = []
    loop {
      toplay = (@songs.keys - @played).first
      if toplay
        @played << toplay
        @client.play @songs[toplay]
      else
        return unless add_autoplay
      end
    }
  end

  def play index
    @client.play @songs[index]
  end
end
end
