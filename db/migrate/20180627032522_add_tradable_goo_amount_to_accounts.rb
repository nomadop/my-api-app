class AddTradableGooAmountToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :tradable_goo_amount, :integer
  end
end
