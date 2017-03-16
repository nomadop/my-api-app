class CreateSellHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :sell_histories do |t|
      t.string :classid
      t.timestamp :datetime
      t.float :price
      t.integer :amount

      t.timestamps
    end
    add_index :sell_histories, [:classid, :datetime], unique: :true
  end
end
