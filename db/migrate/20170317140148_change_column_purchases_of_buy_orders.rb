class ChangeColumnPurchasesOfBuyOrders < ActiveRecord::Migration[5.0]
  def up
    change_column :buy_orders, :purchases, :jsonb, using: 'CAST(purchases AS jsonb)'
  end

  def down
    change_column :buy_orders, :purchases, :json, using: 'CAST(purchases AS json)'
  end
end
