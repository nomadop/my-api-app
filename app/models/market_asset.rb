class MarketAsset < ApplicationRecord
  include ActAsGooItem
  self.inheritance_column = nil
  self.primary_key = :classid

  has_one :inventory_description, foreign_key: :classid
  has_one :order_histogram, primary_key: :item_nameid, foreign_key: :item_nameid

  scope :by_game_name, ->(name) { where('type SIMILAR TO ?', "#{name} (#{Market::ALLOWED_ASSET_TYPE.join('|')})") }
  scope :trading_card, -> { where('type LIKE \'%Trading Card\'') }

  after_create :load_order_histogram, :load_goo_value

  def load_order_histogram
    return false if item_nameid.nil?

    ApplicationJob.perform_unique(LoadOrderHistogramJob, item_nameid)
  end

  def load_goo_value
    return false if owner_actions.nil?

    ApplicationJob.perform_unique(GetGooValueJob, classid)
  end

  def price_per_goo
    return Float::INFINITY if order_histogram.nil? || goo_value.nil?

    1.0 * order_histogram.lowest_sell_order / goo_value
  end

  def price_per_goo_exclude_vat
    return Float::INFINITY if order_histogram.nil? || goo_value.nil?

    1.0 * order_histogram.lowest_sell_order_exclude_vat / goo_value
  end
end
