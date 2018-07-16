class LoadOrderHistogramJob < ApplicationJob
  queue_as :order_histogram
  rescue_from RestClient::TooManyRequests, with: :retry_now
  rescue_from RestClient::Forbidden, with: :retry_now
  rescue_from RestClient::Exceptions::OpenTimeout, with: :retry_now
  rescue_from TOR::NoAvailableInstance, with: :retry_now
  rescue_from TOR::InstanceNotAvailable, with: :retry_now

  def perform(item_nameid)
    Market.load_order_histogram(item_nameid)
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
