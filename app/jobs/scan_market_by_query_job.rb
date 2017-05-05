class ScanMarketByQueryJob < ApplicationJob
  queue_as :market_search

  def perform(query, start, count)
    result = Market.search_by_query(query, start, count)
    return false unless result['success']

    Market.handle_search_result(result)

    tail = start + count
    ScanMarketByQueryJob.perform_later(query, tail, count) if tail < result['total_count']
  end
end
