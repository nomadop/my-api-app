class MyHistory < ApplicationRecord
  belongs_to :account
  belongs_to :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name

  scope :buy, -> { where('who_acted_with like ?', '卖家%') }
  scope :sell, -> { where('who_acted_with like ?', '买家%') }
  scope :on_sell, -> { where(who_acted_with: '物品上架') }
  scope :off_sell, -> { where(who_acted_with: '物品下架') }
  scope :booster_pack, -> { where('market_hash_name like ?', '%Booster Pack') }
  scope :foil, -> { where('market_hash_name like ?', '%Foil%') }
  scope :with_in, ->(duration) { where('created_at > ?', duration.ago) }
end
