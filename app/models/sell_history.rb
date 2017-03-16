class SellHistory < ApplicationRecord
  belongs_to :market_asset, primary_key: :classid, foreign_key: :classid

  scope :with_in, ->(duration) { where('datetime > ?', duration.ago) }
  scope :higher_than, ->(price) { where('price >= ?', price) }

  class << self
    def total_amount
      sum(:amount)
    end

    def total_price
      sum('price * amount')
    end

    def avg_price
      pluck('SUM(price * amount) / SUM(amount)').first
    end

    def sell_rate(price)
      1.0 * higher_than(price).total_amount / total_amount
    end
  end

  def datetime=(datetime)
    datetime = DateTime.strptime(datetime, '%b %d %Y %H: %z').to_time if datetime.is_a?(String)
    super(datetime)
  end
end
