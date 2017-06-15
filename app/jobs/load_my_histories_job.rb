class LoadMyHistoriesJob < ApplicationJob
  queue_as :market_search

  def perform(start, count)
    result = Market.request_my_history(start, count)
    return false unless result['success']

    import_result = Market.handle_my_history_result(result)
    return if import_result.ids.blank?

    tail = start + count
    LoadMyHistoriesJob.perform_later(tail, count) if tail < result['total_count']
  end
end