class SellHistory < ApplicationRecord
  belongs_to :market_asset, primary_key: :classid, foreign_key: :classid

  def datetime=(datetime)
    datetime.is_a?(DateTime) ? super : super(DateTime.parse(datetime))
  end
end
