class ScanMarketJob < ApplicationJob
  queue_as :market_search

  def perform(query, start, count)
    result = Market.search(query, start, count)
    return false unless result['success']

    Market.handle_search_result(result, query)

    tail = start + count
    ScanMarketJob.perform_later(query, tail, count) if tail < result['total_count']
  end
end
