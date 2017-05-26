class LoadFriendProfileJob < ApplicationJob
  queue_as :default

  def perform(id)
    friend = Friend.find(id)
    friend.load_profile_data
  end
end
