class AddColumnsToAccountHistories < ActiveRecord::Migration[5.0]
  def change
    add_column :account_histories, :total_text, :string
    add_column :account_histories, :change_text, :string
    add_column :account_histories, :balance_text, :string
  end
end
