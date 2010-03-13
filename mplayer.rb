require 'net/http'

class MPlayer
  include DRbUndumped
  attr_reader :client, :buffer, :stream_buffer, :offset, :thread
  attr_reader :stream, :process, :state, :total_size, :streamed_size
  attr_reader :position, :position_str, :length, :length_str, :paused
  
  def self.stream server, key, client=nil
    url = "http://#{server}/stream.php"
    url = URI.parse url
    http = Net::HTTP.new url.host, url.port
    req = Net::HTTP::Post.new url.request_uri, {'Cookie' => "PHPSESSID=#{$session}"}
    req.set_form_data({'streamKey' => key}, ';')
    mplayer = self.new client
    mplayer.play_from_http http, req
    mplayer.close
  end

  def initialize client=nil
    @file = "/tmp/remora-#{(rand*100000000).to_i}"
    `mkfifo #{@file}` # TODO: do this nicer
    if client.use_aoss
      @process = IO.popen("aoss mplayer #{@file} -demuxer lavf -slave 2>&1", 'w+')
    else
      @process = IO.popen("mplayer #{@file} -demuxer lavf -slave 2>&1", 'w+')
    end
    @stream = File.open(@file, 'w')
    @buffer = ''
    @stream_buffer = ''
    @offset = 0
    @state = :uninited
    @client = client
    @client.player = self
    @paused = false
  end
  
  def pause
    @process.puts 'pause'
    @paused = !@paused
  end
  
  def stop
    @process.puts 'stop'
    @client.player = nil
    close
    @client.now_playing = nil
  end
  
  def close
    @thread.kill rescue nil
    @stream.close rescue nil
    @process.close rescue nil
    `rm #{@file}` if File.exists? @file
  end

  def time_to_s seconds
    sec ||= 0
    minutes = seconds.to_i/60
    "#{minutes}:#{(seconds.to_i-(minutes*60)).to_s.rjust 2, '0'}"
  end
  
  def handle_stdout
    @last_pos ||= 0
    @buffer += @process.read_nonblock(1024).gsub("\r", "\n")
    
    while @buffer.include?("\n")
      line = @buffer.slice!(0, @buffer.index("\n") + 1).chomp
      if line =~ /^A: +([0-9.]+) \(([0-9.:]+)\) of ([0-9.]+) \(([0-9.:]+)\) +([0-9.,?]+)%/
        @position, @position_str = $1.to_i, $2
        @length, @length_str = $3.to_i, $4
      elsif line =~ /^A: +([0-9.]+) \(([0-9.:]+)\) of 0\.0 \(unknown\) +([0-9.,?]+)%/
        @position, @position_str = $1.to_i, $2
      else
        control = @client.display.panes[:log].controls[:output]
        control.data << line.gsub("\e[J", '')
        control.data.shift while control.data.size > control.height
        @client.display.dirty! :log
        next
      end
      
      @client.display.panes[:np].controls[:cue].value2 = @position
      @client.display.panes[:np].controls[:position].text = "#{time_to_s @position} / #{time_to_s @client.now_playing.duration} (" + (@state == :playing ? "-#{time_to_s @client.now_playing.duration - @position})" : "#{@stream_buffer.size / 1024} / #{@total_size / 1024} KiB)")
      
      if @last_pos < @position
        @client.display.dirty! :np
        @last_pos = @position
      end
    end
  rescue Errno::EAGAIN
  end

  def play_from_http http, req
    @thread = Thread.new do
      begin
        stream_from_http http, req
        @state = :playing
      rescue => ex
        $display.undo_modes
        puts ex.class, ex.message, ex.backtrace
        exit
      end
    end
    
    sleep 0.1 until @total_size && @total_size > 0
    
    until @stream_buffer.size >= @total_size && @offset >= @total_size
      sleep 0.1 until @stream_buffer.size > @offset
      data = @stream_buffer[@offset, 512]
      @offset += data.size
      @stream.write data
      @stream.flush
      
      handle_stdout
    end
    
    wait_for_exit
    
  rescue IOError, Errno::EPIPE => ex
    $display.undo_modes
    puts ex.class, ex.message, ex.backtrace
    close rescue nil
    exit
  end

  def stream_from_http http, req
    http.request(req) do |res|
      @state = :starting_stream
      @total_size = res.header['Content-Length'].to_i
      
      if @total_size && @total_size > 0
        @client.display.panes[:np].controls[:cue].maximum = @total_size
        @client.display.panes[:np].controls[:cue].value = 0
        @client.display.dirty! :np
      end
      
      last_report = 0
      
      res.read_body do |chunk|
        if chunk.size > 0
          @stream_buffer << chunk
          @state = :streaming
          
          @client.display.panes[:np].controls[:cue].value = @stream_buffer.size
          @client.display.panes[:np].controls[:position].text = "#{time_to_s @position} / #{time_to_s @client.now_playing.duration} (#{@stream_buffer.size / 1024} / #{@total_size / 1024} KiB)"
          
          last_report += chunk.size
          if last_report > 102400
            @client.display.dirty! :np
            last_report -= 102400
          end
        end
      end
      
      case res
        when Net::HTTPSuccess
          #puts "success"
        when Net::HTTPRedirection
          url = URI.parse(res['location'])
          stream_from_http Net::HTTP.new(url.host, url.port), Net::HTTP::Get.new(url.request_uri, {'Cookie' => "PHPSESSID=#{$session}"})
          break
        else
          puts "error!"
          exit
      end
    end
  rescue => ex
    $display.undo_modes
    puts ex.class, ex.message, ex.backtrace
    exit
  end
  
  def wait_for_exit
    @state = :waiting
    @stream.close
    until @process.eof?
      handle_stdout
      sleep 0.1
    end
    close
    @state = :complete
  end
end
