class ScanMarketJob < ApplicationJob
  queue_as :default

  def perform(query, start, count)
    result = Market.search(query, start, count)
    return false unless result['success']

    Market.save_search_result(result)

    tail = start + count
    ScanMarketJob.perform_later(query, tail, count) if tail < result['total_count']
  rescue Exception => e
    ps = Sidekiq::ProcessSet.new
    ps.each(&:quiet!)
    ps.each(&:stop!)
    raise e
  end
end
