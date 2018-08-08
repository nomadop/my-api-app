class OrderHistogram < ApplicationRecord
  MAX_SCHEDULE_INTERVAL = 8.day.to_i
  MIN_SCHEDULE_INTERVAL = 1.5.hour.to_i

  belongs_to :market_asset, primary_key: :item_nameid, foreign_key: :item_nameid
  has_many :my_listings, through: :market_asset
  has_many :histories, class_name: 'OrderHistogramHistory', primary_key: :item_nameid, foreign_key: :item_nameid

  scope :with_my_listing, -> { find(joins(:my_listing).distinct.pluck(:id)) }
  scope :without_my_listing, -> { left_outer_joins(:my_listing).where(my_listings: { classid: nil }) }
  scope :sack_of_gems, -> { joins(:market_asset).where(market_assets: { market_hash_name: '753-Sack of Gems' }) }

  class << self
    def refresh_all
      find_each do |order_histogram|
        LoadOrderHistogramJob.perform_later(order_histogram.item_nameid)
      end
    end

    def sog_graphs(split = true)
      order_histogram = sack_of_gems.take.refresh
      split ? order_histogram.sell_order_graphs : order_histogram.sell_order_graph
    end

    def import_json_file(path)
      json = JSON.parse(File.read(path))
      json.each_slice(1000) do |slice|
        transaction do
          slice.each do |item|
                order_histogram = find_by(item_nameid: item['item_nameid'])
                order_histogram.update(item)
          end
        end
      end
    end
  end

  class OrderGraph < Struct.new(:price, :amount); end

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

  def refresh_interval
    scheduled_histories = histories.with_timestamp.since(scheduled_at).order(:created_at).to_a
    return schedule_interval if scheduled_histories.count < 4

    uniq_count = scheduled_histories
      .uniq { |history| "#{history.highest_buy_order},#{history.lowest_sell_order}" }
      .count
    new_interval = if uniq_count >= 4
      [schedule_interval / 2, MIN_SCHEDULE_INTERVAL].max
    elsif uniq_count == 1
      [schedule_interval * 2, MAX_SCHEDULE_INTERVAL].min
    else
      schedule_interval
    end
    new_interval.tap { update(schedule_interval: new_interval, scheduled_at: Time.now) }
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
