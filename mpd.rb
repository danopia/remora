require 'lineconnection'

module Remora
  class MPDConnection < LineConnection
    attr_accessor :client
    
    def initialize client
      super
      @client = client
    end
    
    def post_init
      super
      send_line 'OK MPD 0.12.2'
    end
    
    def receive_line line
      args = line.split
      case args.first
        when 'password'
          puts "Got a password"
          send_line 'OK'
        
        when 'outputs'
          puts "Output listing request"
          send_line "outputid: 0"
          send_line "outputname: Speakers"
          send_line "outputenabled: 1"
          send_line 'OK'
        
        when 'enableoutput'
          puts "Output enabling request"
          send_line 'ACK Not supported'
        
        when 'disableoutput'
          puts "Output disabling request"
          send_line 'ACK Not supported'
          
        when 'status'
          puts "Status request"
          send_line 'volume: 100'
          send_line 'repeat: 0'
          send_line 'random: 0'
          #~ send_line 'playlist: 0'
          #~ send_line 'playlistlength: 0'
          send_line 'xfade: 0'
          send_line 'state: stop'
          #~ send_line 'song: 0'
          #~ send_line 'songid: 0'
          #~ send_line 'time: 0:0'
          #~ send_line 'bitrate: 0'
          #~ send_line 'audio: 0:0:0'
          #~ send_line 'updating_db: 0'
          #~ send_line 'error: none'
          #~ send_line 'nextsong: 1'
          #~ send_line 'nextsongid: 1'
          send_line 'OK'
        
        when 'currentsong'
          send_line 'file: albums/bob_marley/songs_of_freedom/disc_four/12.bob_marley_-_could_you_be_loved_(12"_mix).flac'
          send_line 'Time: 327'
          send_line 'Album: Songs Of Freedom - Disc Four'
          send_line 'Artist: Bob Marley'
          send_line 'Title: Could You Be Loved (12" Mix)'
          send_line 'Track: 12'
          send_line 'Pos: 11'
          send_line 'Id: 6601'
          send_line 'OK'
        
        when 'playlistinfo'
          send_line 'file: albums/bob_marley/songs_of_freedom/disc_four/12.bob_marley_-_could_you_be_loved_(12"_mix).flac'
          send_line 'Time: 327'
          send_line 'Album: Songs Of Freedom - Disc Four'
          send_line 'Artist: Bob Marley'
          send_line 'Title: Could You Be Loved (12" Mix)'
          send_line 'Track: 12'
          send_line 'Pos: 11'
          send_line 'Id: 6601'
          send_line 'OK'
        
        when 'lsinfo'
          send_line 'file: albums/bob_marley/songs_of_freedom/disc_four/12.bob_marley_-_could_you_be_loved_(12"_mix).flac'
          send_line 'Time: 327'
          send_line 'Album: Songs Of Freedom - Disc Four'
          send_line 'Artist: Bob Marley'
          send_line 'Title: Could You Be Loved (12" Mix)'
          send_line 'Track: 12'
          send_line 'Pos: 11'
          send_line 'Id: 6601'
          send_line 'OK'
      end
    end
  end
end

EventMachine.run {
  EventMachine::start_server "0.0.0.0", 8000, Remora::MPDConnection, nil
  puts 'Ready.'
}
