class TorNewnymJob < ApplicationJob
  queue_as :default

  def perform()
    Utility.tor_newnym
  end
end
