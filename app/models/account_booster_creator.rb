class AccountBoosterCreator < ApplicationRecord
  belongs_to :account
  belongs_to :booster_creator, primary_key: :appid, foreign_key: :appid

  scope :unavailable, -> { where(unavailable: true) }

  def available?
    return true if available_at_time.nil?
    Time.now > available_at
  end

  def available_at
    available_at_time.blank? ? Time.at(0) : DateTime.parse(available_at_time).to_time
  end
end
