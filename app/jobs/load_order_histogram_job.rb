class LoadOrderHistogramJob < ApplicationJob
  queue_as :order_histogram

  def perform(item_nameid)
    Market.load_order_histogram(item_nameid)
  end

  rescue_from(RuntimeError) do |e|
    if e.message == 'load order histogram failed with code 104'
      clean_job_concurrence
    else
      raise e
    end
  end
end
