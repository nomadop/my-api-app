class RemoveTimestampsFromOrderHistogramHistories < ActiveRecord::Migration[5.0]
  def change
    remove_column :order_histogram_histories, :created_at, :string
    remove_column :order_histogram_histories, :updated_at, :string
  end
end
