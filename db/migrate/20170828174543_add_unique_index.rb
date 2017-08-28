class AddUniqueIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :likes, [:track_name, :artist_name], unique: true
  end
end
