class MPlayer
  include DRbUndumped
  attr_reader :client, :buffer, :stream_buffer, :offset, :thread
  attr_reader :stream, :state, :total_size, :streamed_size
  attr_reader :position, :position_str, :length, :length_str
  
  def self.play server, key, client=nil
    url = "http://#{server}/stream.php"
    url = URI.parse url
    http = Net::HTTP.new url.host, url.port
    req = Net::HTTP::Post.new url.request_uri, {'Cookie' => "PHPSESSID=#{$session}"}
    req.set_form_data({'streamKey' => key}, ';')
    mplayer = self.new client
    mplayer.play_from_http http, req
  end

  def initialize client=nil
    @stream = IO.popen('mplayer - -demuxer lavf 2>&1', 'w+')
    @buffer = ''
    @stream_buffer = ''
    @offset = 0
    @state = :uninited
    @client = client
    @client.player = self
  end

  def time_to_s seconds
    sec ||= 0
    minutes = seconds.to_i/60
    "#{minutes}:#{(seconds.to_i-(minutes*60)).to_s.rjust 2, '0'}"
  end
  
  def handle_stdout
    @buffer += @stream.read_nonblock(1024).gsub("\r", "\n")
    
    while @buffer.include?("\n")
      line = @buffer.slice!(0, @buffer.index("\n") + 1).chomp
      if line =~ /^A: +([0-9.]+) \(([0-9.:]+)\) of ([0-9.]+) \(([0-9.:]+)\)  ([0-9.,?]+)%/
        @position, @position_str = $1.to_i, $2
        @length, @length_str = $3.to_i, $4
      elsif line =~ /^A: +([0-9.]+) \(([0-9.:]+)\) of 0\.0 \(unknown\)  ([0-9.,?]+)%/
        @position, @position_str = $1.to_i, $2
      else
        control = @client.display.panes[:log].controls[:output]
        control.data << line.gsub("\e[J", '')
        control.data.shift while control.data.size > control.height
        @client.display.dirty! :log
        next
      end
      
      @client.display.panes[:np].controls[:cue].value2 = @position
      @client.display.panes[:np].controls[:position].text = "#{time_to_s @position} / #{time_to_s @client.now_playing['EstimateDuration']} (" + (@state == :playing ? "-#{time_to_s @client.now_playing['EstimateDuration'].to_i - @position})" : "#{@stream_buffer.size / 1024} / #{@total_size / 1024} KiB)")
      @client.display.dirty! :np
    end
  rescue Errno::EAGAIN
  end

  def play_from_http http, req
    @thread = Thread.new do
      stream_from_http http, req
      @state = :playing
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
  end

  def stream_from_http http, req
    @thread = Thread.new do
      http.request(req) do |res|
        @state = :starting_stream
        @total_size = res.header['Content-Length'].to_i
        
        if @total_size && @total_size > 0
          @client.display.panes[:np].controls[:cue].maximum = @total_size
          @client.display.panes[:np].controls[:cue].value = 0
          @client.display.dirty! :np
        end
        
        res.read_body do |chunk|
          if chunk.size > 0
            @stream_buffer << chunk
            @state = :streaming
            
            @client.display.panes[:np].controls[:cue].value = @stream_buffer.size
            @client.display.panes[:np].controls[:position].text = "#{time_to_s @position} / #{time_to_s @client.now_playing['EstimateDuration']} (#{@stream_buffer.size / 1024} / #{@total_size / 1024} KiB)"
            @client.display.dirty! :np
          end
        end
        
        case res
          when Net::HTTPSuccess
            #puts "success"
          when Net::HTTPRedirection
            url = URI.parse(res['location'])
            stream_from_http Net::HTTP.new(url.host, url.port), Net::HTTP::Get.new(url.request_uri, {'Cookie' => "PHPSESSID=#{$session}"})
            return
          else
            puts "error!"
            exit
        end
      end
    end
  end
  
  def wait_for_exit
    @state = :waiting
    @stream.close_write
    until @stream.eof?
      handle_stdout
      sleep 0.1
    end
    @stream.close
    @state = :complete
  end
end
