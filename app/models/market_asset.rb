class MarketAsset < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil
  self.primary_key = :classid

  has_one :inventory_description, foreign_key: :classid
  has_one :order_histogram, primary_key: :item_nameid, foreign_key: :item_nameid

  def load_order_histogram
    return false if item_nameid.nil?

    queue = Sidekiq::Queue.new
    in_queue = queue.any? { |job| job.display_class == 'LoadOrderHistogramJob' && job.display_args == [item_nameid] }
    return false if in_queue

    LoadOrderHistogramJob.perform_later(item_nameid)
  end

  def load_goo_value
    return false if owner_actions.nil?

    queue = Sidekiq::Queue.new
    in_queue = queue.any? { |job| job.display_class == 'GetGooValueJob' && job.display_args == [classid] }
    return false if in_queue

    GetGooValueJob.perform_later(classid)
  end

  def price_per_goo
    return Float::INFINITY if item_nameid.nil? || goo_value.nil?

    1.0 * order_histogram.lowest_sell_order / goo_value
  end

  def price_per_goo_exclude_vat
    return Float::INFINITY if item_nameid.nil? || goo_value.nil?

    1.0 * order_histogram.lowest_sell_order_exclude_vat / goo_value
  end
end
