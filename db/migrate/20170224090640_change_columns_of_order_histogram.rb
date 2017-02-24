class ChangeColumnsOfOrderHistogram < ActiveRecord::Migration[5.0]
  def change
    change_column :order_histograms, :highest_buy_order, :integer, using: 'CAST(highest_buy_order AS integer)'
    change_column :order_histograms, :lowest_sell_order, :integer, using: 'CAST(lowest_sell_order AS integer)'
  end
end
