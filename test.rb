require 'client'
require 'mplayer'
require 'dbus-interface'

client = GrooveShark::Client.new
$session = client.session
puts "Session is #{client.session}"
puts "Communication token is #{client.comm_token}"
puts "Queue is #{client.queue}"

run_dbus client

puts "Searching for 'people are crazy':"
results = client.search_songs('people are crazy')['Return']
results.each do |result|
  puts "#{results.index result} - #{result['Name']} - #{result['ArtistName']} - #{result['AlbumName']}"
end

puts
puts "Please type in a song index to [attempt to] play it:"
index = gets.to_i

#client.enqueue results[index]

puts "calling play()"
client.play results[index]
puts "play() terminated"
