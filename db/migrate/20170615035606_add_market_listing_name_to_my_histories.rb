class AddMarketListingNameToMyHistories < ActiveRecord::Migration[5.0]
  def change
    add_column :my_histories, :market_listing_name, :string
  end
end
