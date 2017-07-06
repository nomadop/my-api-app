class ChangeColumnItemsOfAccountHistories < ActiveRecord::Migration[5.0]
  def up
    remove_column :account_histories, :items
    add_column :account_histories, :items, :jsonb
  end

  def down
    remove_column :account_histories, :items
    add_column :account_histories, :items, :string
  end
end
