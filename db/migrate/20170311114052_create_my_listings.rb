class CreateMyListings < ActiveRecord::Migration[5.0]
  def change
    create_table :my_listings do |t|
      t.string :listingid
      t.string :classid
      t.string :market_hash_name

      t.timestamps
    end
  end
end
