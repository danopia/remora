require 'net/https'
require 'uri'

require 'rubygems'
require 'json'

module GrooveShark
class JSONSock
  attr_reader :http, :uri
  attr_accessor :session

  def initialize server, session=nil
    @session = session

    @uri = URI.parse server
    @http = Net::HTTP.new @uri.host, @uri.port
    @http.use_ssl = true if ssl?
  end

  def ssl?; @uri.scheme == 'https'; end

  def post url, data
    url = @uri + URI.parse(url)
    req = Net::HTTP::Post.new url.request_uri, headers
    res = @http.request req, data.to_json
    $sock.puts res.body if $sock
    JSON.parse res.body
  end

  def headers
    {'Content-type' => 'application/json', 'Cookie' => "PHPSESSID=#{@session}"}
  end

  def close
    @http.finish if @http.started?
  end
end
end

