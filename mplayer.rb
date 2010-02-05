require 'open3'

def play server, key
  url = "http://#{server}/stream.php"
  url = URI.parse url
  http = Net::HTTP.new url.host, url.port
  req = Net::HTTP::Post.new url.request_uri
  req.set_form_data({'streamKey' => key}, ';')
  mplayer = start_mplayer
  stream_from_http http, req, mplayer
end

def start_mplayer
  puts "starting mplayer"
  
  stream = IO.popen('mplayer - -demuxer lavf', 'w+')
  Thread.new do
    line = stream.read 1024
    while line
      line = stream.read 1024
    end
  end
  puts "started mplayer"
  stream
end

def stream_from_http http, req, output
  puts "starting request"
  http.request(req) do |res|
    puts "started request"
    size, total = 0, res.header['Content-Length'].to_i
    res.read_body do |chunk|
      if chunk.size > 0
        size += chunk.size
        print "\r%d%% done (%d of %d)" % [(size * 100) / total, size, total]
        STDOUT.flush
        output.print chunk
      else
      end
    end
    puts
    case res
    when Net::HTTPSuccess
      puts "success"
    when Net::HTTPRedirection
      puts "redirect to #{res['location']}"
      url = URI.parse(res['location'])
      stream_from_http Net::HTTP.new(url.host, url.port), Net::HTTP::Get.new(url.request_uri, {'Cookie' => "PHPSESSID=#{$session}"}), output
      puts "redirect done"
      return
    else
      puts "error"
    end
  end
  output.close_write
  puts "waiting for output to finish"
  until output.eof?
    sleep 1
  end
  output.close
  puts "output is closed"
end
