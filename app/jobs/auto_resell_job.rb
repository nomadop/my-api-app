class AutoResellJob < ApplicationJob
  queue_as :default

  def perform()
    unless Time.now.hour.between?(9, 21)
      AutoResellJob.set(wait: 1.hour).perform_later()
      return
    end

    MyListing.auto_resell
    AutoResellJob.set(wait: 15.minutes).perform_later()
  end
end
