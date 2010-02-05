class MPlayer
  attr_accessor :stream, :length, :position, :length2, :position2
  def self.play server, key
    url = "http://#{server}/stream.php"
    url = URI.parse url
    http = Net::HTTP.new url.host, url.port
    req = Net::HTTP::Post.new url.request_uri
    req.set_form_data({'streamKey' => key}, ';')
    mplayer = self.new
    mplayer.stream_from_http http, req
  end

  def initialize
    puts "starting mplayer"
    
    @stream = IO.popen('mplayer - -demuxer lavf', 'w+')
    @buffer = ''
  end
  
  def handle_stdout
    @buffer += @stream.read_nonblock(1024).gsub("\r", "\n")
    
    while @buffer.include?("\n")
      line = @buffer.slice!(0, @buffer.index("\n") + 1).chomp
      p line
    end
  rescue Errno::EAGAIN
  end
  
#A:   6.1 (6.1) of 211.0 (03:31.0)  0.7%
#A:  66.2 (01:06.2) of 211.0 (03:31.0)  0.7%
#A: 136.5 (02:16.5) of 211.0 (03:31.0)  0.7%

  def stream_from_http http, req
    puts "starting request"
    http.request(req) do |res|
      puts "started request"
      size, total = 0, res.header['Content-Length'].to_i
      res.read_body do |chunk|
        if chunk.size > 0
          size += chunk.size
          print "\r%d%% done (%d of %d)" % [(size * 100) / total, size, total]
          STDOUT.flush
          @stream.print chunk
          @stream.flush
          handle_stdout
        end
      end
      puts
      case res
      when Net::HTTPSuccess
        puts "success"
      when Net::HTTPRedirection
        puts "redirect to #{res['location']}"
        url = URI.parse(res['location'])
        stream_from_http Net::HTTP.new(url.host, url.port), Net::HTTP::Get.new(url.request_uri, {'Cookie' => "PHPSESSID=#{$session}"})
        puts "redirect done"
        return
      else
        puts "error"
      end
    end
    
    wait_for_exit
  end
  
  def wait_for_exit
    @stream.close_write
    puts "waiting for output to finish"
    until @stream.eof?
      handle_stdout
      sleep 0.1
    end
    @stream.close
    puts "output is closed"
  end
end
