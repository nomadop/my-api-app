class GetGooValueJob < ApplicationJob
  queue_as :goo_value

  def perform(classid)
    description = MarketAsset.find(classid)
    goo_value = description.get_goo_value
    description.update(goo_value: goo_value)
  end
end
