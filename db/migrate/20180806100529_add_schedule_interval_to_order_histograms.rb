class AddScheduleIntervalToOrderHistograms < ActiveRecord::Migration[5.0]
  def change
    add_column :order_histograms, :schedule_interval, :integer, default: 6.hours.to_i
  end
end
