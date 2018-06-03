class AlterOrderHistograms < ActiveRecord::Migration[5.0]
  def up
    remove_index :order_histograms, [:item_nameid, :latest]
    remove_index :order_histograms, [:item_nameid, :created_at]
    remove_column :order_histograms, :latest
    remove_column :order_histograms, :truncate_lock
    add_index :order_histograms, :item_nameid, unique: true
  end

  def down
    remove_index :order_histograms, :item_nameid
    add_column :order_histograms, :truncate_lock, :boolean, default: false
    add_column :order_histograms, :latest, :boolean
    add_index :order_histograms, [:item_nameid, :created_at]
    add_index :order_histograms, [:item_nameid, :latest], unique: true
  end
end
