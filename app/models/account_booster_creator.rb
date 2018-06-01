class AccountBoosterCreator < ApplicationRecord
  belongs_to :account
  belongs_to :booster_creator, primary_key: :appid, foreign_key: :appid

  scope :unavailable, -> { where(unavailable: true) }

  delegate :bot_name, to: :account

  class << self
    def times
      find_each.map(&:available_time)
    end
  end

  def available?
    return true if available_at_time.nil?
    Time.now > available_at
  end

  def available_at
    available_at_time.blank? ? Time.at(0) : available_time
  end

  def available_time
    return nil if available_at_time.nil?
    time_str = available_at_time.gsub('下午', 'PM').gsub('上午', 'AM')
    DateTime.strptime(time_str, '%m月%d日%P%I:%M').getlocal('+08:00')
  end
end
