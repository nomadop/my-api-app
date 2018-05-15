class AddTruncateLockToOrderHistograms < ActiveRecord::Migration[5.0]
  def change
    add_column :order_histograms, :truncate_lock, :boolean, default: false
  end
end
