class LoadOrderHistogramJob < ApplicationJob
  queue_as :order_histogram

  def perform(item_nameid, concurrence_uuid = nil)
    JobConcurrence.with_concurrence(concurrence_uuid) do
      Market.load_order_histogram(item_nameid)
    end
  end
end
