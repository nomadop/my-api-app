class LoadMyHistoriesJob < ApplicationJob
  queue_as :load_my_history

  def perform(start, count, account_id, incremental = true)
    result = Market.request_my_history(start, count, account_id)
    return clean_job_concurrence unless result['success']

    import_result = Market.handle_my_history_result(result, account_id)
    return clean_job_concurrence if incremental && import_result&.ids.blank?

    tail = start + count
    LoadMyHistoriesJob.perform_later(tail, count, account_id, incremental) if tail < result['total_count']
    clean_job_concurrence
  end
end
