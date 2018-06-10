class SellHistory < ApplicationRecord
  belongs_to :market_asset, primary_key: :classid, foreign_key: :classid

  scope :with_in, ->(duration) { where('datetime > ?', duration.ago.to_date) }
  scope :higher_than, ->(price) { where('price >= ?', price) }
  scope :group_by_day, -> { group('CAST(datetime AS DATE)') }

  class << self
    def total_amount
      sum(&:amount)
    end

    def total_price
      sum { |history| history.price * history.amount }
    end

    def avg_price
      total_price / total_amount
    end

    def average_price
      pluck('SUM(price * amount) / SUM(amount)').first
    end

    def sell_rate(price)
      highers = select { |history| history.price >= price }
      1.0 * highers.sum(&:amount) / total_amount
    end
  end

  def as_json
    super(only: [:price, :amount], methods: [:formatted_time])
  end

  def datetime=(datetime)
    datetime = DateTime.strptime(datetime, '%b %d %Y %H: %z').to_time if datetime.is_a?(String)
    super(datetime)
  end

  def formatted_time
    datetime.getlocal('+08:00')
  end
end
