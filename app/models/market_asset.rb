class MarketAsset < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil
  self.primary_key = :classid

  has_one :inventory_description, foreign_key: :classid
  has_one :order_histogram, primary_key: :item_nameid, foreign_key: :item_nameid

  def load_order_histogram
    return false if item_nameid.empty?

    queue = Sidekiq::Queue.new
    in_queue = queue.any? { |job| job.display_class == 'LoadOrderHistogramJob' && job.display_args == [item_nameid] }
    return false if in_queue

    LoadOrderHistogramJob.perform_later(item_nameid)
  end
end
