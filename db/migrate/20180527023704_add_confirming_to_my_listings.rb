class AddConfirmingToMyListings < ActiveRecord::Migration[5.0]
  def change
    add_column :my_listings, :confirming, :boolean, default: false
  end
end
