class CreateTradeOffers < ActiveRecord::Migration[5.0]
  def change
    create_table :trade_offers do |t|
      t.integer :account_id
      t.string :trade_offer_id
      t.string :partner_id
      t.string :partner_name

      t.timestamps
    end
    add_index :trade_offers, :trade_offer_id, unique: true
  end
end
