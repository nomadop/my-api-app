class AddIndexOfSellHistories < ActiveRecord::Migration[5.0]
  def change
    add_index :sell_histories, :classid
  end
end
