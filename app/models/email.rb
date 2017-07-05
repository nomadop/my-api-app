class Email < ApplicationRecord
  belongs_to :account, primary_key: :to, foreign_key: :email_address

  scope :from_steam, -> { where(from: 'noreply@steampowered.com') }
end
