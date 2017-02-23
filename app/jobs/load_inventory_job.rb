class LoadInventoryJob < ApplicationJob
  queue_as :default

  def perform()
    Inventory.load_all!
  end
end
