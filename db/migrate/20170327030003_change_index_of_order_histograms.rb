class ChangeIndexOfOrderHistograms < ActiveRecord::Migration[5.0]
  def up
    remove_index :order_histograms, :item_nameid
    add_index :order_histograms, [:item_nameid, :created_at]
  end

  def down
    remove_index :order_histograms, [:item_nameid, :created_at]
    add_index :order_histograms, :item_nameid, unique: true
  end
end
