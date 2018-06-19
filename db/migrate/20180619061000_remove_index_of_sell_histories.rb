class RemoveIndexOfSellHistories < ActiveRecord::Migration[5.0]
  def change
    remove_index :sell_histories, [:classid, :datetime]
  end
end
