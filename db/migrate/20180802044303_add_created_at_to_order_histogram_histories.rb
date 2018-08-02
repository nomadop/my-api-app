class AddCreatedAtToOrderHistogramHistories < ActiveRecord::Migration[5.0]
  def change
    add_column :order_histogram_histories, :created_at, :datetime
  end
end
