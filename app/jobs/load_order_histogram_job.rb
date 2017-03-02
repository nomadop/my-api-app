class LoadOrderHistogramJob < ApplicationJob
  queue_as :default

  def perform(item_nameid)
    Market.load_order_histogram(item_nameid)
  end
end
