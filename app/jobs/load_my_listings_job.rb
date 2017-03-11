class LoadMyListingsJob < ApplicationJob
  queue_as :market_search

  def perform(start, count)
    result = Market.request_my_listings(start, count)
    return false unless result['success']

    Market.handle_my_listing_result(result)

    tail = start + count
    LoadMyListingsJob.perform_later(tail, count) if tail < result['total_count']
  end
end
