class SellHistory < ApplicationRecord
  belongs_to :market_asset, primary_key: :classid, foreign_key: :classid

  def datetime=(datetime)
    datetime = DateTime.strptime(datetime, '%b %d %Y %H: %z').to_time if datetime.is_a?(String)
    super(datetime)
  end
end
