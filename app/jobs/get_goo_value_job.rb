class GetGooValueJob < ApplicationJob
  queue_as :default

  def perform(classid)
    description = MarketAsset.find(classid)
    goo_value = description.get_goo_value
    description.update(goo_value: goo_value)
  rescue Exception => e
    ps = Sidekiq::ProcessSet.new
    ps.each(&:quiet!)
    ps.each(&:stop!)
    raise e
  end
end
