class BoosterCreation < ApplicationRecord
  belongs_to :account
  belongs_to :booster_creator
end
