# +-----------------------+--------+----------+--------+--------+
# | Field                 |  Favs  | Playlist | Search | Radio  |
# +-----------------------+--------+----------+--------+--------+
# | SongID                | String |  String  | String | Number |
# | AlbumID               | String |  String  | String | Number |
# | ArtistID              | String |  String  | String | Number |
# +-----------------------+--------+----------+--------+--------+
# | Name                  | String |  String  | String |        |
# | SongName              |        |          | String | String |
# | AlbumName             | String |  String  | String | String |
# | ArtistName            | String |  String  | String | String |
# +-----------------------+--------+----------+--------+--------+
# | QuerySongClicks       |        |          | String |        |
# | QueryAlbumClicks      |        |          | String |        |
# | QueryArtistClicks     |        |          | String |        |
# +-----------------------+--------+----------+--------+--------+
# | SongPlays             |        |          | Number |        |
# | ArtistPlays           |        |          | Number |        |
# +-----------------------+--------+----------+--------+--------+
# | SongClicks            |        |          | Number |        |
# | AlbumClicks           |        |          | Number |        |
# | ArtistClicks          |        |          | Number |        |
# +-----------------------+--------+----------+--------+--------+
# | IsVerified            | String |          | String |        |
# | SongVerified          |        |          | String |        |
# | AlbumVerified         |        |          | String |        |
# | ArtistVerified        |        |          | String |        |
# +-----------------------+--------+----------+--------+--------+
# | CoverArtFilename      | String |  String  | String |        |
# | CoverArtUrl           |        |          |        | String |
# | TrackNum              | ?????? |  ??????  | ?????? |        | Can be null
# | Year                  |        |          | String |        |
# +-----------------------+--------+----------+--------+--------+
# | AvgDuration           |        |          | String |        |
# | EstimateDuration      | String |  String  | String | Number |
# | IsLowBitrateAvailable |        |          | String |        |
# +-----------------------+--------+----------+--------+--------+
# | Popularity            | String |  String  | String |        |
# | SphinxWeight          |        |          | Number |        |
# | Score                 |        |          | Float  |        |
# | AvgRating             |        |          | String |        | Can be null
# +-----------------------+--------+----------+--------+--------+
# | DSName                |        |          | String |        | May be used for radio seeds?
# | DALName               |        |          | String |        | May be used for radio seeds?
# | DAName                |        |          | String |        |
# +-----------------------+--------+----------+--------+--------+
# | Flags                 | String |  String  | String | String |
# | Sort                  |        |  String  |        |        | "0" to "9.45228e+37"?
# | source                |        |          |        | String | recommended, user, sponsored
# | SponsoredAutoplayID   |        |          |        | Number | 0?
# | TSFavorited           | String |          |        |        | 2010-01-09 20:11:50
# +-----------------------+--------+----------+--------+--------+

module GrooveShark
class Song
  attr_reader :id, :data
  
  def initialize data=nil
    @data = data
    @id = data['SongID'].to_i
  end
  
  def title
    @data['SongName'] || @data['Name']
  end
  
  def to_s
    "#{title} - #{@data['ArtistName']} - #{@data['AlbumName']}"
  end
  
  def duration
    @data['EstimateDuration'].to_i
  end
  
  def source
    @data['source'] || 'user'
  end
end
end
