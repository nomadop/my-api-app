class AddYourOfferCountAndTheirOfferCountToTradeOffers < ActiveRecord::Migration[5.0]
  def change
    add_column :trade_offers, :your_offer_count, :integer
    add_column :trade_offers, :their_offer_count, :integer
  end
end
