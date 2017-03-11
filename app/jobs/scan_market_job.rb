class ScanMarketJob < ApplicationJob
  queue_as :market_search

  def perform(appid, start, count)
    result = Market.search(appid, start, count)
    return false unless result['success']

    Market.handle_search_result(result)

    tail = start + count
    ScanMarketJob.perform_later(appid, tail, count) if tail < result['total_count']
  end
end
