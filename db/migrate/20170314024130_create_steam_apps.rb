class CreateSteamApps < ActiveRecord::Migration[5.0]
  def change
    create_table :steam_apps do |t|
      t.string :type
      t.string :name
      t.integer :steam_appid
      t.boolean :is_free
      t.json :categories
      t.json :genres

      t.timestamps
    end
    add_index :steam_apps, :steam_appid, unique: :true
  end
end
