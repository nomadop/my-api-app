class AddEmailAddressToAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :email_address, :string
  end
end
