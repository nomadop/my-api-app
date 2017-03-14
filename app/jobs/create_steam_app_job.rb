class CreateSteamAppJob < ApplicationJob
  queue_as :default

  def perform(appid)
    Steam.create_app(appid)
  end
end
