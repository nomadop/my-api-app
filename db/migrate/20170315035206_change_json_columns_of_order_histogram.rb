class ChangeJsonColumnsOfOrderHistogram < ActiveRecord::Migration[5.0]
  def up
    change_column :order_histograms, :buy_order_graph, :jsonb, using: 'CAST(buy_order_graph AS jsonb)'
    change_column :order_histograms, :sell_order_graph, :jsonb, using: 'CAST(sell_order_graph AS jsonb)'
  end

  def down
    change_column :order_histograms, :buy_order_graph, :json, using: 'CAST(buy_order_graph AS json)'
    change_column :order_histograms, :sell_order_graph, :json, using: 'CAST(sell_order_graph AS json)'
  end
end
