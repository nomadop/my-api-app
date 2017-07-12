class AddEmailPasswordToAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :email_password, :string
  end
end
