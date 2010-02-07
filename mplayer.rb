class MPlayer
  include DRbUndumped
  attr_reader :client
  attr_reader :stream, :state, :total_size, :streamed_size
  attr_reader :position, :position_str, :length, :length_str
  
  def self.play server, key, client=nil
    url = "http://#{server}/stream.php"
    url = URI.parse url
    http = Net::HTTP.new url.host, url.port
    req = Net::HTTP::Post.new url.request_uri, {'Cookie' => "PHPSESSID=#{$session}"}
    req.set_form_data({'streamKey' => key}, ';')
    mplayer = self.new client
    mplayer.stream_from_http http, req
  end

  def initialize client=nil
    @stream = IO.popen('mplayer - -demuxer lavf 2>&1', 'w+')
    @buffer = ''
    @state = :uninited
    @client = client
    @client.player = self
  end
  
  def handle_stdout
    @buffer += @stream.read_nonblock(1024).gsub("\r", "\n")
    
    while @buffer.include?("\n")
      line = @buffer.slice!(0, @buffer.index("\n") + 1).chomp
      if line =~ /^A: +([0-9.]+) \(([0-9.:]+)\) of ([0-9.]+) \(([0-9.:]+)\)  ([0-9.]+)%/
        @position, @position_str = $1, $2
        @length, @length_str = $3, $4
      elsif line =~ /^A: +([0-9.]+) \(([0-9.:]+)\) of 0\.0 \(unknown\)  ([0-9.]+)%/
        @position, @position_str = $1, $2
      end
    end
  rescue Errno::EAGAIN
  end

  def stream_from_http http, req
    http.request(req) do |res|
      @state = :starting_stream
      @streamed_size = 0
      @total_size = res.header['Content-Length'].to_i
      res.read_body do |chunk|
        if chunk.size > 0
          @state = :streaming
          @streamed_size += chunk.size
          #print "\r%d%% done (%d of %d)" % [(size * 100) / total, size, total]
          STDOUT.flush
          @stream.print chunk
          @stream.flush
          handle_stdout
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
    
    wait_for_exit
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
