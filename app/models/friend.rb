class Friend < ApplicationRecord
  scope :no_steamid, -> { where(steamid: nil) }

  class << self
    def refresh
      Steam.load_friends
      load_profile_data
    end

    def load_profile_data
      no_steamid.find_each(&:load_profile_data_later)
    end
  end

  def load_profile_data
    profile_data = Steam.get_profile_data(profile_url)
    update(steamid: profile_data['steamid'])
  end

  def load_profile_data_later
    ApplicationJob.perform_unique(LoadFriendProfileJob, id)
  end
end
