class LoadOrderHistogramJob < ApplicationJob
  queue_as :default

  def perform(item_nameid)
    Market.load_order_histogram(item_nameid)
  rescue Exception => e
    ps = Sidekiq::ProcessSet.new
    ps.each(&:quiet!)
    ps.each(&:stop!)
    raise e
  end
end
