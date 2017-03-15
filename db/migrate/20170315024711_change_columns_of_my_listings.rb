class ChangeColumnsOfMyListings < ActiveRecord::Migration[5.0]
  def change
    remove_column :my_listings, :classid
    add_column :my_listings, :price, :integer
    add_column :my_listings, :listed_date, :string
  end
end
