class AddStatusToTradeOffers < ActiveRecord::Migration[5.0]
  def change
    add_column :trade_offers, :status, :integer, default: 0
  end
end
