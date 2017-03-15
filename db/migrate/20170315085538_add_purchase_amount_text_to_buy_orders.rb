class AddPurchaseAmountTextToBuyOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :buy_orders, :purchase_amount_text, :text
  end
end
