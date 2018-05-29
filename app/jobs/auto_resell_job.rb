class AutoResellJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    MyListing.auto_resell(Account.find(account_id))
    AutoResellJob.set(wait: 30.minutes).perform_later(account_id)
  end
end
