class AddLatestToOrderHistograms < ActiveRecord::Migration[5.0]
  def change
    add_column :order_histograms, :latest, :boolean
  end
end
