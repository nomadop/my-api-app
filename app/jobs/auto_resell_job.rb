class AutoResellJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    account_id.nil? ? MyListing.auto_resell_all : MyListing.auto_resell(Account.find(account_id))
    AutoResellJob.set(wait: 30.minutes).perform_later(account_id)
  end
end
