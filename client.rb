require File.join(File.dirname(__FILE__), 'json_sock')
require File.join(File.dirname(__FILE__), 'queue')

require 'digest/md5'
require 'digest/sha1'

require 'open-uri'

module GrooveShark
class Client
  include DRbUndumped
  attr_accessor :session, :comm_token, :queue, :now_playing, :player, :display, :use_aoss
  attr_reader :user_id, :username, :premium, :playlists
  
  UUID = '996A915E-4C56-6BE2-C59F-96865F748EAE'
  CLIENT = 'gslite'
  CLIENT_REV = '20100115.09'
  
  def initialize session=nil
    @session = session || get_session
    get_comm_token
    @queue = Queue.new self
    
    @premium = false
    @playlists = {}
  end
  
  def request page, method, parameters=nil, secure=false
    url = "http#{secure ? 's' : ''}://cowbell.grooveshark.com/#{page}.php?#{method}"
    request = {
      'header' => {
        'session' => @session,
        'uuid' => UUID,
        'client' => CLIENT,
        'clientRevision' => CLIENT_REV,
      },
      'method' => method,
      'parameters' => parameters,
    }
    request['header']['token'] = create_token(method) if @comm_token
    
    data = GrooveShark::JSONSock.post url, request
    
    # maybe they have a use :P
    puts "Have #{data['header']['alerts'].size} alerts" if data['header'] && data['header']['alerts'] && data['header']['alerts'].size != 2
    
    return data['result'] unless data['fault']
    
    if data['fault']['code'] == 256
      $sock.puts "Getting new token" if $sock
      get_comm_token
      sleep 1
      return request(page, method, parameters)
    end
    
    $sock.puts "Grooveshark returned fault code #{data['fault']['code']}: #{data['fault']['message']}"
    nil
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
  
  # {"userID":1839825,"username":"danopia","isPremium":"0",
  # "autoAutoplay":false,"authRealm":1,"favoritesLimit":500,
  # "librarySizeLimit":5000,"uploadsEnabled":1,"themeID":""}
  def auth user, pass
    results = request_service 'authenticateUserEx', {:username => 'danopia', :password => 'nSlpxQKo'}, true
    
    @user_id = results['userID']
    @username = results['username']
    @premium = results['isPremium']
    
    fetch_playlists
    
    results
  end
  
  # [{"PlaylistID"=>"22432605", "Name"=>"Country", "About"=>"", "Picture"=>""},
  #  {"PlaylistID"=>"22671463", "Name"=>"Non-country", "About"=>"", "Picture"=>""}]
  def fetch_playlists
    results = request_more('userGetPlaylists', :userID => @user_id)['Playlists']
    
    results.each do |result|
      @playlists[result['PlaylistID']] = result
    end
    
    results
  end
  
  def get_comm_token
    @comm_token = nil # so that it doesn't send a token
    @comm_token = request_service 'getCommunicationToken', {'secretKey' => Digest::MD5.hexdigest(@session)}, true
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
  
  # streamKey, streamServer, streamServerID
  def get_stream_auth song_id
    data = request_more 'getStreamKeyFromSongID', {"songID" => song_id, "prefetch" => false}
    data['result']
  end
  
  def play song_info
    @display.panes[:np].controls[:song_name].text = "#{song_info['SongName'] || song_info['Name']} - #{song_info['ArtistName']} - #{song_info['AlbumName']}"
    @display.panes[:np].controls[:cue].value = 0
    @display.panes[:np].controls[:cue].maximum = 1
    @display.panes[:np].controls[:cue].value2 = 0
    @display.panes[:np].controls[:cue].maximum2 = song_info['EstimateDuration'].to_i
    @display.dirty! :np
    
    @now_playing = song_info
    key = get_stream_auth song_info['SongID']
    MPlayer.stream key['streamServer'], key['streamKey'], self
    @now_playing = nil
    
    
  end
end
end
