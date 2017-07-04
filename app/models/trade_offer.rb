class TradeOffer < ApplicationRecord
  belongs_to :account

  enum status: [:pending, :accepted, :declined]
end
