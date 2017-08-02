class MyHistory < ApplicationRecord
  belongs_to :account
  belongs_to :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name

  scope :buy, -> { where('who_acted_with like ?', '卖家%') }
  scope :sell, -> { where('who_acted_with like ?', '买家%') }
  scope :booster_pack, -> { where('market_hash_name like ?', '%Booster Pack') }
  scope :with_in, ->(duration) { where("to_date(listed_date, '已购买: FMMM月DD日') > ?", duration.ago) }
end
