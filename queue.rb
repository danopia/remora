module GrooveShark
class Queue
  include DRbUndumped
  attr_accessor :songs, :order, :next_index, :id, :client
  
  def initialize client
    @client = client
    @id = @client.request_service 'initiateQueueEx'
    
    @songs = {}
    @order = []
    @next_index = 1
    
    redraw_queue
  end
  
  def << song
    @client.request_service 'addSongsToQueueExt', {
      'songIDsArtistIDs' => [{
        'artistID' => song.data['ArtistsID'],
        'songID' => song.id,
        'songQueueSongID' => @next_index,
        'source' => song.source,
      }],
      'songQueueID' => @id
    }
    @songs[@next_index] = song
    @order << song
    @next_index += 1
    
    redraw_queue
    
    @next_index - 1
  end
  
  def redraw_queue
    return unless @client.display
    @client.display.panes[:queue].controls[:songs].data = @order.map {|song| song.to_s }
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
    @order.delete @songs[index]
    @songs.delete index
    
    redraw_queue
  end
  
  def add_autoplay
    self << pick_autoplay
  end
  
  def pick_autoplay
    seeds = {}
    @order.last(5).each {|song| seeds[song.data['ArtistID'].to_s] = 'p' }
    
    Song.new @client.request_service('getSongForAutoplayExt', {
      'recentSongs' => @order.last(5).map{|song| song.id },
      'secondaryArtistWeightModifier' => 0.9,
      'seedArtistWeightRange' => [70, 100],
      'maxDuration' => 1500,
      'minDuration' => 60,
      'weightModifierRange' => [-9, 9],
      'frowns' => [],
      'recentArtists' => seeds.keys,
      'seeds' => seeds,
      'songQueueID' => @id
    })
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
        $sock.puts @songs[toplay].inspect
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
