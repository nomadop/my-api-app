class GetNotificationCountsJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    Utility.timeout(5) do
      @account = Account.find(account_id)
      Steam.get_notification_counts(@account)
    end
    ApplicationJob.perform_unique(GetNotificationCountsJob, account_id)
  end

  rescue_from(RestClient::Unauthorized) do
    @account.refresh
    retry_job
  end
end
