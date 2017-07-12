class GetNotificationCountsJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    Utility.timeout(10) do
      @account = Account.find(account_id)
      Steam.get_notification_counts(@account)
    end
    GetNotificationCountsJob.perform_later(account_id)
  end

  rescue_from(RestClient::Unauthorized) do
    @account.refresh
    retry_job
  end

  rescue_from(OpenSSL::SSL::SSLError) do
    retry_job
  end
end
