class PullOrderActivityJob < ApplicationJob
  queue_as :default

  def perform(item_nameid)
    Utility.timeout(5.seconds) do
      Market.pull_order_activity(item_nameid)
    end

    ApplicationJob.perform_unique(PullOrderActivityJob, item_nameid)
  end
end
