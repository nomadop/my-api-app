class LoadAccountHistoryJob < ApplicationJob
  queue_as :default

  def perform(account_id, cursor = nil, one_page = true)
    next_cursor = Steam.load_account_history(Account.enabled.find(account_id), cursor)
    LoadAccountHistoryJob.perform_later(account_id, next_cursor) unless next_cursor.nil? || one_page
  end
end
