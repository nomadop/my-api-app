class AddAccountIdToMyListings < ActiveRecord::Migration[5.0]
  def change
    add_column :my_listings, :account_id, :integer, default: 1
  end
end
