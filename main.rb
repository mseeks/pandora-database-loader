require "active_record"
require "active_record_upsert"
require "pandata"
require "pg"
require "rufus-scheduler"

ENV["TZ"] = "America/Chicago"

scheduler = Rufus::Scheduler.new

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

scheduler.every "1d" do
  data = Pandata::Scraper.get(ENV["PANDORA_EMAIL"])
  likes = data.likes(:tracks)

  likes.each do |like|
    Like.upsert(
      artist_name: like[:artist],
      track_name: like[:track]
    )
  end
end

scheduler.join
