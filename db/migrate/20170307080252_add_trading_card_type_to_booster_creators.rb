class AddTradingCardTypeToBoosterCreators < ActiveRecord::Migration[5.0]
  def change
    add_column :booster_creators, :trading_card_type, :string
  end
end
