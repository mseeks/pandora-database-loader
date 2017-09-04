require "active_record"
require "active_record_upsert"
require "base64"
require "json"
require "pandata"
require "pg"
require "rest-client"

db_config = {
  host:     ENV["DB_HOST"],
  adapter:  "postgresql",
  encoding: "utf-8",
  database: ENV["DB_NAME"],
  username: ENV["DB_USERNAME"],
  password: ENV["DB_PASSWORD"]
}
ActiveRecord::Base.establish_connection(db_config)

class Like < ActiveRecord::Base
  upsert_keys [:track_name, :artist_name]
end

spotify = RestClient::Resource.new("https://api.spotify.com/v1")

encoded_auth = Base64.strict_encode64("#{ENV["SPOTIFY_CLIENT_ID"]}:#{ENV["SPOTIFY_CLIENT_SECRET"]}")
spotify_access_token = JSON.parse(RestClient.post("https://accounts.spotify.com/api/token", {
  grant_type: "client_credentials"
},
  Authorization: "Basic #{encoded_auth}").body
)["access_token"]

spotify_headers = {
  accept: "application/json",
  Authorization: "Bearer #{spotify_access_token}"
}

data = Pandata::Scraper.get(ENV["PANDORA_EMAIL"])
likes = data.likes(:tracks)

likes.each do |like|
  begin
    results = JSON.parse(spotify["search"].get({
      params: {
        q: "#{like[:track]} #{like[:artist]}",
        type: "track"
      }
    }.merge(spotify_headers)).body)["tracks"]["items"]

    if record = results.first
      spotify_track_id = record["id"]

      spotify_track = JSON.parse(spotify["tracks/#{spotify_track_id}"].get(spotify_headers).body)
      spotify_track_audio_features = JSON.parse(spotify["audio-features/#{spotify_track_id}"].get(spotify_headers).body)
      spotify_track_audio_analysis = JSON.parse(spotify["audio-analysis/#{spotify_track_id}"].get(spotify_headers).body)

      Like.upsert(
        artist_name: like[:artist],
        track_name: like[:track],
        track_information: spotify_track,
        track_audio_features: spotify_track_audio_features,
        track_audio_analysis: spotify_track_audio_analysis
      )
    end
  rescue => e
    puts "An error of type #{e.class} happened, message is #{e.message}"
  end
end
