class CreateOrderHistogramHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :order_histogram_histories do |t|
      t.string :item_nameid
      t.integer :highest_buy_order
      t.integer :lowest_sell_order

      t.timestamps
      t.index :item_nameid
    end
  end
end
