class AddPriceToBuyOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :buy_orders, :price, :integer
  end
end
