require 'json_sock'
require 'queue'

require 'digest/md5'
require 'digest/sha1'

require 'open-uri'

module GrooveShark
class Client
  include DRbUndumped
  attr_accessor :session, :comm_token, :queue, :now_playing, :queue
  
  UUID = '996A915E-4C56-6BE2-C59F-96865F748EAE'
  CLIENT = 'gslite'
  CLIENT_REV = '20100115.09'
  
  def initialize session=nil
    @session = session || get_session
    @comm_token = get_comm_token
    @queue = Queue.new self
  end
  
  def request page, method, parameters=nil
    data = GrooveShark::JSONSock.post "http://cowbell.grooveshark.com/#{page}.php?#{method}", {
      'header' => {
        'token' => create_token(method),
        'session' => @session,
        'uuid' => UUID,
        'client' => CLIENT,
        'clientRevision' => CLIENT_REV,
      },
      'parameters' => parameters,
      'method' => method,
    }
    
    # maybe they have a use :P
    puts "Have #{data['header']['alerts'].size} alerts" if data['header'] && data['header']['alerts'] && data['header']['alerts'].size != 2

    data['result']
  end
  
  # These refer to the two different pages that cowbell uses.
  def request_service *params
    request 'service', *params
  end
  def request_more *params
    request 'more', *params
  end
  
  def get_session
    page = open('http://listen.grooveshark.com/').read
    page =~ /sessionID: '([0-9a-f]+)'/
    $1
  end
  
  def get_comm_token
    data = GrooveShark::JSONSock.post 'https://cowbell.grooveshark.com/service.php', {
      'header' => {
        'session' => @session,
        'uuid' => UUID,
        'client' => CLIENT,
        'clientRevision' => CLIENT_REV,
      },
      'parameters' => {
        'secretKey' => Digest::MD5.hexdigest(@session),
      },
      'method' => 'getCommunicationToken'
    }

    data['result']
  end
  
  def create_token method
    rnd = rand(256**3).to_s(16).rjust(6, '0')
    plain = [method, @comm_token, 'theColorIsRed', rnd].join(':')
    hash = Digest::SHA1.hexdigest plain
    "#{rnd}#{hash}"
  end
  
  def search type, query
    request_more 'getSearchResults', {:type => type, :query => query}
  end
  def search_songs query
    search 'Songs', query
  end
  
  def enqueue song_id, artist_id
    request_service 'addSongsToQueueExt', {
      'songIDsArtistIDs' => [{
        'songID' => song_id,
        'songQueueSongID' => 1,
        'artistID' => artist_id,
        'source' => 'user',
      }],
      'songQueueID' => @queue,
    }
  end
  
  # streamKey, streamServer, streamServerID
  def get_stream_auth song_id
    data = request_more 'getStreamKeyFromSongID', {"songID" => song_id, "prefetch" => false}
    data['result']
  end
  
  def play song_info
    @now_playing = song_info
    key = get_stream_auth song_info['SongID']
    MPlayer.play key['streamServer'], key['streamKey']
    @now_playing = nil
  end
end
end
