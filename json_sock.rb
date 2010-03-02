require 'net/https'
require 'uri'

require 'rubygems'
require 'json'

module GrooveShark
class JSONSock
  def self.post url, data
    url = URI.parse url
    http = Net::HTTP.new url.host, url.port
    req = Net::HTTP::Post.new url.path, {'Content-type' => 'application/json', 'Cookie' => "PHPSESSID=#{$session}"}
    http.use_ssl = true if url.port == 443
    res = http.request req, data.to_json
    $sock.puts res.body if $sock
    JSON.parse res.body
  end
end
end
