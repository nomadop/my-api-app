class AddCountryToSteamUesrs < ActiveRecord::Migration[5.0]
  def change
    add_column :steam_users, :country, :string
  end
end
