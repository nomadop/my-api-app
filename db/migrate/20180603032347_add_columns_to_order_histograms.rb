class AddColumnsToOrderHistograms < ActiveRecord::Migration[5.0]
  def change
    add_column :order_histograms, :cached_highest_buy, :integer
    add_column :order_histograms, :cached_lowest_buy, :integer
    add_column :order_histograms, :cached_highest_sell, :integer
    add_column :order_histograms, :cached_lowest_sell, :integer
    add_index :order_histograms, [:item_nameid, :latest], unique: true
  end
end
