class OrderHistogram < ApplicationRecord
  belongs_to :market_asset, primary_key: :item_nameid, foreign_key: :item_nameid
  has_many :my_listings, through: :market_asset

  scope :with_my_listing, -> { find(joins(:my_listing).distinct.pluck(:id)) }
  scope :without_my_listing, -> { left_outer_joins(:my_listing).where(my_listings: {classid: nil}) }
  scope :latest, -> { where(latest: true) }
  scope :sack_of_gems, -> { joins(:market_asset).where(market_assets: { market_hash_name: '753-Sack of Gems' }) }

  class << self
    def refresh_all
      find_each do |order_histogram|
        LoadOrderHistogramJob.perform_later(order_histogram.item_nameid)
      end
    end

    def sog_graphs
      sack_of_gems.take.refresh.sell_order_graphs
    end
  end

  class OrderGraph < Struct.new(:price, :amount); end

  def latest!
    update(latest: true)
  end

  def overdue!
    update(latest: false)
  end

  def proportion
    1.0 * highest_buy_order / lowest_sell_order
  rescue
    0
  end

  def order_count
    (sell_order_count || 0) + (buy_order_count || 0)
  end

  def highest_buy_order_exclude_vat
    Utility.exclude_val(highest_buy_order)
  end

  def lowest_sell_order_exclude_vat
    Utility.exclude_val(lowest_sell_order)
  end

  def refresh
    Market.load_order_histogram(item_nameid)
  end

  def refresh_later
    ApplicationJob.perform_unique(LoadOrderHistogramJob, item_nameid)
  end

  def get_order_graphs(graph_data)
    my_listing_count = my_listings.group(:price).count
    return [] if graph_data.blank?
    graph_data.reduce([]) do |result, graph|
      price = (graph[0] * 100).round
      amount = graph[1] - result.sum(&:amount) - (my_listing_count[price] || 0)
      amount > 0 ? result.push(OrderGraph.new(price, amount)) : result
    end
  end

  def buy_order_graphs
    get_order_graphs(buy_order_graph)
  end

  def sell_order_graphs
    get_order_graphs(sell_order_graph)
  end

  def highest_buy_order_graph
    buy_order_graphs.first
  end

  def lowest_sell_order_graph
    sell_order_graphs.first
  end

  def buy_order_count
    buy_order_graph.blank? ? 0 : buy_order_graph.last[1]
  end

  def sell_order_count
    sell_order_graph.blank? ? 0 : sell_order_graph.last[1]
  end

  def sell_rate(price)
    lowers = sell_order_graphs.select { |graph| graph.price <= price }
    1.0 * lowers.sum(&:amount) / sell_order_graphs.sum(&:amount)
  end
end
