class AccountBoosterCreator < ApplicationRecord
  belongs_to :account
  belongs_to :booster_creator, primary_key: :appid, foreign_key: :appid

  def available?
    return true if available_at_time.nil?
    Time.now > DateTime.parse(available_at_time)
  end
end
