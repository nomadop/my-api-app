class AddRefundedToAccountHistories < ActiveRecord::Migration[5.0]
  def change
    add_column :account_histories, :refunded, :boolean
  end
end
