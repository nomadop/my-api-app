class OrderHistogramHistory < ApplicationRecord
  scope :since, ->(time) { where('created_at > ?', time) }
  scope :with_in, ->(duration) { since(duration.ago) }
  scope :with_timestamp, -> { where.not(created_at: nil) }
  default_scope { order(:created_at) }
end
