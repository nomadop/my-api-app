class AddStatusDescToTradeOffers < ActiveRecord::Migration[5.0]
  def change
    add_column :trade_offers, :status_desc, :string
  end
end
