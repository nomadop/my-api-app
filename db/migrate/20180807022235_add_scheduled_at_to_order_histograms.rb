class AddScheduledAtToOrderHistograms < ActiveRecord::Migration[5.0]
  def change
    add_column :order_histograms, :scheduled_at, :datetime, default: Time.at(0)
  end
end
