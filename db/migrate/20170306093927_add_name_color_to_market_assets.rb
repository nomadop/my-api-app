class AddNameColorToMarketAssets < ActiveRecord::Migration[5.0]
  def change
    add_column :market_assets, :name_color, :string
  end
end
