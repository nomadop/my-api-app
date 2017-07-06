class AccountHistory < ApplicationRecord
  self.inheritance_column = nil

  scope :with_in, ->(duration) { where('date > ?', duration.ago) }
  scope :between, ->(from, to) { where(date: (from..to)) }
  scope :market, -> { where(items: 'Steam 社区市场') }
  scope :wallet, -> { where('items like ?', '已购买%钱包资金') }
  scope :income, -> { where('change > 0') }
  scope :expense, -> { where('change < 0') }
end