require 'lineconnection'

begin
  $sock ||= TCPSocket.new('localhost', 5465)
rescue
  $sock ||= File.open('/dev/null', 'w')
end

module Remora
  class MPDConnection < LineConnection
    attr_accessor :client, :list_version, :list_hash, :songs
    
    def initialize client
      super
      @client = client
      @db_version = 0
      @list_version = 0
      @list_hash = nil
      
      @songs = {}
      
      load __FILE__
    end
    
    def post_init
      super
      send_line 'OK MPD 0.12.2'
    end
    
    def time_to_s seconds
      minutes = seconds.to_i / 60
      format('%d:%02d', minutes, (seconds.to_i-(minutes*60)))
    end
    
    def send_song song
      send_line "file: #{song.id}.mp3"
      send_line "Time: #{song.duration}"
      send_line "Album: #{song.album}"
      send_line "Artist: #{song.artist}"
      send_line "Title: #{song.title}"
      # send_line "Track: 12"
      send_line "Pos: #{@client.queue.songs.values.index song}"
      send_line "Id: #{song.id}"
    end
    
    def receive_line line
      if @list_hash != @client.queue.songs.hash
        @list_hash = @client.queue.songs.hash
        @list_version += 1
      end
      
      args = line.split
      case args.first
        when 'password'
          $sock.puts "Got a password"
          send_line 'OK'
        
        when 'outputs'
          $sock.puts "Output listing request"
          send_line "outputid: 0"
          send_line "outputname: Speakers"
          send_line "outputenabled: 1"
          send_line 'OK'
        
        when 'enableoutput'
          $sock.puts "Output enabling request"
          send_line 'ACK Not supported'
        
        when 'disableoutput'
          $sock.puts "Output disabling request"
          send_line 'ACK Not supported'
          
        when 'setvol'
          args[1] =~ /^"([0-9]+)"$/
          vol = $1.to_i
          $sock.puts "Changing volume to #{vol}"
          @client.volume = vol
          send_line 'OK'
          
        when 'status'
          $sock.puts "Status request"
          send_line "volume: #{@client.volume}"
          send_line 'repeat: 0'
          send_line 'random: 0'
          send_line "playlist: #{@list_version}"
          send_line "playlistlength: #{@client.queue.songs.size}"
          send_line 'xfade: 0'
          send_line 'state: ' + (@client.player ? (@client.player.paused ? 'pause' : 'play') : 'stop')
          
          if @client.now_playing && @client.player
            send_line "song: #{@client.queue.songs.values.index @client.now_playing}"
            send_line "songid: #{@client.now_playing.id}"
            send_line "time: #{@client.player.position}:#{@client.now_playing.duration}"
          end
          
          #~ send_line 'bitrate: 0'
          #~ send_line 'audio: 0:0:0'
          if @list_version > @db_version
            @db_version = @list_version
            send_line "updating_db: #{@db_version}"
          end
          #~ send_line 'error: none'
          #~ send_line 'nextsong: 1'
          #~ send_line 'nextsongid: 1'
          send_line 'OK'
        
        when 'currentsong'
          song = @client.now_playing
          send_song song if song
          send_line 'OK'
        
        when 'playlistinfo'
          @client.queue.songs.values.each do |song|
            send_song song
          end
          send_line 'OK'
        
        when 'lsinfo'
          @client.queue.songs.values.each do |song|
            send_song song
          end
          send_line 'OK'
          
        when 'stats'
          send_line 'artists: 1'
          send_line 'albums: 1'
          send_line "songs: #{@client.queue.songs.size}"
          send_line 'uptime: 360'
          send_line 'playtime: 100'
          send_line 'db_playtime: 500'
          send_line "db_update: #{Time.now.to_i}"
          send_line 'OK'
        
        when 'pause'
          @client.player.pause
          send_line 'OK'
        
        when 'listallinfo'
          args[1] =~ /^"([0-9]+)\.mp3"$/
          id = $1.to_i
          song = @client.queue.songs.values.find{|info| info.id == id }
          
          send_song song
          send_line 'OK'
        
        when 'plchanges'
          @client.queue.songs.values.each do |song|
            send_song song
          end
          send_line 'OK'
        
        when 'list'
          @client.queue.songs.values.map{|song| song.data.artist }.uniq.each do |artist|
            send_line "Artist: #{artist}"
          end
          send_line 'OK'
        
        when 'search'
          args[1..-1].join(' ') =~ /"([^"]*)"/
          client.search_songs($1).each do |song|
            @songs[song.id] = song
            send_song song
          end
          send_line 'OK'
        
        when 'add'
          args[1] =~ /^"([0-9]+)\.mp3"$/
          id = $1.to_i
          song = @songs[id]
          @client.queue << song
          send_line 'OK'
        
        when 'find'
          songs = @client.queue.songs.values
          
          args[1..-1].join(' ').scan(/([a-z]+) "([^"]*)"/) do |type, param|
            type = 'ArtistName' if type == 'artist'
            type = 'AlbumName' if type == 'album'
            $sock.puts "Request for songs where #{type} = #{param}"
            songs.reject! {|song| song.data[type] != param }
          end
          
          songs.each do |song|
            send_song send_song
          end
          send_line 'OK'
      end
    
    rescue => ex
      $sock.puts ex, ex.message, ex.backtrace
    end
  end
end
