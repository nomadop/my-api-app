class ChangeColumnsOfSteamApps < ActiveRecord::Migration[5.0]
  def up
    change_column :steam_apps, :categories, :jsonb, using: 'CAST(categories AS jsonb)'
    change_column :steam_apps, :genres, :jsonb, using: 'CAST(genres AS jsonb)'
  end

  def down
    change_column :steam_apps, :categories, :json, using: 'CAST(categories AS json)'
    change_column :steam_apps, :genres, :json, using: 'CAST(genres AS json)'
  end
end
