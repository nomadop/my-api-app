class AddAccountIdToBuyOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :buy_orders, :account_id, :integer
  end
end
