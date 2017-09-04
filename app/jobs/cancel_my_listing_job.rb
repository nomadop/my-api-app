class CancelMyListingJob < ApplicationJob
  queue_as :cancel_my_listing

  def perform(listing_id)
    Market.cancel_my_listing(listing_id)
  end

  rescue_from(RestClient::BadGateway) do |e|
    headers = e.http_headers
    cookies = Utility.parse_cookies(headers[:set_cookie])
    if cookies.any? { |cookie| cookie.value == 'delete' }
      Account::DEFAULT.refresh
      retry_job
    else
      false
    end
  end
end
