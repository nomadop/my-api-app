class AccountBoosterCreator < ApplicationRecord
  belongs_to :account
  belongs_to :booster_creator, primary_key: :appid, foreign_key: :appid
end
