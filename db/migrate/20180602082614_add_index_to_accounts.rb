class AddIndexToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_index :accounts, :account_id, unique: true
  end
end
