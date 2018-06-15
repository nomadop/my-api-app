class LoadOrderHistogramJob < ApplicationJob
  queue_as :order_histogram

  def perform(item_nameid)
    Market.load_order_histogram(item_nameid)
  end

  rescue_from(
    RestClient::TooManyRequests, RestClient::Forbidden,
    TOR::NoAvailableInstance, TOR::InstanceNotAvailable,
  ) do
    retry_job
  end
end
