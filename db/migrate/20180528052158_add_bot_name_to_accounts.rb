class AddBotNameToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :bot_name, :string
  end
end
