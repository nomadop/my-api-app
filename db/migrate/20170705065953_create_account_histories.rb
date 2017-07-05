class CreateAccountHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :account_histories do |t|
      t.integer :account_id
      t.timestamp :date
      t.string :items
      t.string :type
      t.string :payment
      t.integer :total
      t.integer :change
      t.integer :balance

      t.timestamps
    end
  end
end
