class LoadMyHistoriesJob < ApplicationJob
  queue_as :load_my_history

  def perform(start, count, account_id = 1)
    @account_id = account_id
    result = Market.request_my_history(start, count, account_id)
    return clean_job_concurrence unless result['success']

    import_result = Market.handle_my_history_result(result, account_id)
    return clean_job_concurrence if import_result.ids.blank?

    tail = start + count
    LoadMyHistoriesJob.perform_later(tail, count, account_id) if tail < result['total_count']
  end

  rescue_from(Authentication::AccountExpired) do
    Account.find(@account_id).refresh
    retry_job
  end
end
