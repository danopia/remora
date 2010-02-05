require 'client'
require 'mplayer'

client = GrooveShark::Client.new
$session = client.session
puts "Session is #{client.session}"
puts "Communication token is #{client.comm_token}"
puts "Queue is #{client.queue}"

puts "Searching for 'people are crazy':"
results = client.search_songs('people are crazy')['Return']
results.each do |result|
  puts "#{results.index result} - #{result['Name']} - #{result['ArtistName']} - #{result['AlbumName']}"
end

puts
puts "Please type in a song index to [attempt to] play it:"
index = gets.to_i

song_id = results[index]['SongID']
album_id = results[index]['AlbumID']

#client.enqueue(song_id, album_id)

puts "calling play()"
client.play song_id
puts "play() terminated"
