class LoadOrderHistogramJob < ApplicationJob
  queue_as :order_histogram
  rescue_from RestClient::TooManyRequests, with: :retry_now
  rescue_from RestClient::Forbidden, with: :retry_now
  rescue_from RestClient::Exceptions::OpenTimeout, with: :retry_now
  rescue_from TOR::NoAvailableInstance, with: :retry_now
  rescue_from TOR::InstanceNotAvailable, with: :retry_now

  def perform(item_nameid, schedule = false)
    order_histogram = OrderHistogram.find_by(item_nameid: item_nameid)
    order_histogram.refresh
    if schedule
      # market_asset = MarketAsset.find_by(item_nameid: item_nameid)
      # market_asset.update(goo_value: market_asset.get_goo_value) unless market_asset.nil?
      LoadOrderHistogramJob.set(wait: order_histogram.schedule_interval).perform_later(item_nameid, schedule)
    end
  end

  def retry_now
    retry_job
  end

  rescue_from(RuntimeError) do |e|
    if e.message == 'load order histogram failed with code 104'
      clean_job_concurrence
    else
      raise e
    end
  end
end
