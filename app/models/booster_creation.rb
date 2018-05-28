class BoosterCreation < ApplicationRecord
  belongs_to :account
  belongs_to :booster_creator, counter_cache: true

  scope :with_in, ->(duration) { where('booster_creations.created_at > ?', duration.ago) }

  class << self
    def total_price
      includes(:booster_creator).sum(:price)
    end
  end
end
