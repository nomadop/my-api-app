class CancelMyListingJob < ApplicationJob
  queue_as :cancel_my_listing

  def perform(id)
    my_listing = MyListing.find(id)
    my_listing.cancel
  end
end
