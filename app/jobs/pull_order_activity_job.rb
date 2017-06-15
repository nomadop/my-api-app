class PullOrderActivityJob < ApplicationJob
  queue_as :default

  def perform(item_nameid)
    Market.pull_order_activity(item_nameid)

    ApplicationJob.perform_unique(PullOrderActivityJob, item_nameid, wait: 5.seconds)
  end
end
