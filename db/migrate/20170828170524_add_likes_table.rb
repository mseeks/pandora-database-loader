class AddLikesTable < ActiveRecord::Migration[5.0]
  def change
    create_table :likes do |t|
      t.string :track_name, index: true
      t.string :artist_name, index: true

      t.timestamps
    end
  end
end
