class LoadInventoryJob < ApplicationJob
  queue_as :default

  def perform()
    puts 'Loading Inventory...'
    sleep 60
  end
end
