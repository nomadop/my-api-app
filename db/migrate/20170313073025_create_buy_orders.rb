class CreateBuyOrders < ActiveRecord::Migration[5.0]
  def change
    create_table :buy_orders do |t|
      t.string :buy_orderid
      t.integer :active
      t.integer :purchased
      t.json :purchases
      t.integer :quantity
      t.integer :quantity_remaining
      t.integer :success
      t.string :market_hash_name

      t.timestamps
    end
    add_index :buy_orders, :buy_orderid, unique: :true
  end
end
