class CreateOrderHistograms < ActiveRecord::Migration[5.0]
  def change
    create_table :order_histograms do |t|
      t.string :item_nameid
      t.string :highest_buy_order
      t.string :lowest_sell_order
      t.json :buy_order_graph
      t.json :sell_order_graph
      t.timestamps
    end
    add_index :order_histograms, :item_nameid, unique: true
  end
end
