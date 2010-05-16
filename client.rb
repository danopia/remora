require File.join(File.dirname(__FILE__), 'json_sock')
require File.join(File.dirname(__FILE__), 'queue')

require 'digest/md5'
require 'digest/sha1'

require 'open-uri'

module GrooveShark
class Client
  include DRbUndumped
  attr_accessor :session, :comm_token, :queue, :now_playing, :player, :display, :use_aoss
  attr_reader :user, :sock, :secure_sock
  
  UUID = '996A915E-4C56-6BE2-C59F-96865F748EAE'
  CLIENT = 'gslite'
  CLIENT_REV = '20100412.09'
  
  # "country":{"CC1":"0","CC3":"0","ID":"223","CC2":"0","CC4":"1073741824"}
  
  COWBELL = 'cowbell.grooveshark.com'
  
  def initialize session=nil
    @session = session || get_session
    
    @sock = JSONSock.new "http://#{COWBELL}/", @session
    @secure_sock = JSONSock.new "https://#{COWBELL}/", @session
    
    get_comm_token
    @queue = create_queue
    
    @premium = false
    @playlists = {}
    @favorites = []
  end
  
  def request page, method, parameters=nil, secure=false
    url = "/#{page}.php?#{method}"
    request = {
      'header' => {
        'session' => @session,
        'uuid' => UUID,
        'client' => CLIENT,
        'clientRevision' => CLIENT_REV,
        'country' => {"CC1"=>"0","CC3"=>"0","ID"=>"223","CC2"=>"0","CC4"=>"1073741824"},
      },
      'method' => method,
      'parameters' => parameters,
    }
    request['header']['token'] = create_token(method) if @comm_token
    
    if secure
      data = @secure_sock.post url, request
    else
      data = @sock.post url, request
    end
    
    # maybe they have a use :P
    puts "Have #{data['header']['alerts'].size} alerts" if data['header'] && data['header']['alerts'] && data['header']['alerts'].size != 2
    
    return data['result'] unless data['fault']
    
    if data['fault']['code'] == 256
      p data
      $sock.puts "Getting new token" if $sock
      get_comm_token
      sleep 1
      return request(page, method, parameters)
    end
    
    raise "Grooveshark returned fault code #{data['fault']['code']}: #{data['fault']['message']}"
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
  
  def create_queue
    Queue.new self
  end
  
  def login user, pass
    @user = User.login self, user, pass
  end
  
  def get_comm_token
    @comm_token = nil # so that it doesn't send a token
    @comm_token = request_service 'getCommunicationToken', {:secretKey => Digest::MD5.hexdigest(@session)}, true
  end
  
  # shhhhhhh!
  def create_token method
    rnd = rand(256**3).to_s(16).rjust(6, '0')
    plain = [method, @comm_token, 'quitStealinMahShit', rnd].join(':')
    hash = Digest::SHA1.hexdigest plain
    "#{rnd}#{hash}"
  end
  
  def search type, query
    results = request_more 'getSearchResults', {:type => type, :query => query}
    results.map {|song| Song.new song }
  end
  def search_songs query
    search 'Songs', query
  end
  
  # streamKey, streamServer, streamServerID
  def get_stream_auth song
    results = request_more 'getStreamKeyFromSongIDEx', {
      "songID" => song.id,
      "prefetch" => false,
      'mobile' => false,
      'country' => {"CC1"=>"0","CC3"=>"0","ID"=>"223","CC2"=>"0","CC4"=>"1073741824"},
    }
    results#['result']
  end
  
  def play song
    @display.driver.set_title song.to_s
    
    @display.panes[:np].controls[:song_name].text = song.to_s
    @display.panes[:np].controls[:cue].value = 0
    @display.panes[:np].controls[:cue].maximum = 1
    @display.panes[:np].controls[:cue].value2 = 0
    @display.panes[:np].controls[:cue].maximum2 = song.duration
    @display.dirty! :np
    
    @now_playing = song
    key = get_stream_auth song
    # {"uSecs":"273000000","FileToken":"1Uz0O8","streamKey":"9b90e6f64695493ca930","streamServerID":16384,"ip":"stream36akm.grooveshark.com"}
    MPlayer.stream key['ip'], key['streamKey'], self
    @now_playing = nil
    @player = nil
  end
end
end
