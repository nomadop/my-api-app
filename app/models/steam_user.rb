class SteamUser < ApplicationRecord
  def load_profile_data
    profile_data = Steam.get_profile_data(profile_url)
    update(steamid: profile_data['steamid'])
  end

  def set_nickname(nickname)
    result = Steam.set_nickname(self, nickname)
    update(nickname: nickname) if result['success'] == 1
  end

  def add_friend
    Steam.add_friend(self)
  end

  def send_comment(comment)
    Steam.send_comment(self, comment)
  end
end
