class GetGooValueJob < ApplicationJob
  queue_as :default

  def perform(id)
    description = InventoryDescription.find(id)
    description.get_goo_value
  end
end
