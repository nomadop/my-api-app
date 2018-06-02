class SteamUser < ApplicationRecord
  belongs_to :account, primary_key: :account_id, foreign_key: :steamid

  def load_profile_data
    profile_data = Steam.get_profile_data(profile_url)
    update(steamid: profile_data['steamid'])
  end

  def set_nickname(nickname)
    result = Steam.set_nickname(self, nickname)
    case result['success']
      when 1
        return update(nickname: nickname)
      when 8
        Authentication.refresh
        return set_nickname(nickname)
    end
  end

  def add_friend
    Steam.add_friend(self)
  end

  def send_comment(comment)
    Steam.send_comment(self, comment)
  end
end
