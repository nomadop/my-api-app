class LoadAccountHistoryJob < ApplicationJob
  queue_as :default

  def perform(account, cursor = nil)
    next_cursor = Steam.load_account_history(account, cursor)
    LoadAccountHistoryJob.perform_later(account, next_cursor) unless next_cursor.nil?
  end
end
