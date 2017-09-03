class AddJsonFields < ActiveRecord::Migration[5.0]
  def change
    add_column :likes, :track_information, :jsonb
    add_column :likes, :track_audio_features, :jsonb
    add_column :likes, :track_audio_analysis, :jsonb
  end
end
