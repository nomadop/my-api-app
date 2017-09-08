class CancelMyListingJob < ApplicationJob
  queue_as :cancel_my_listing

  def perform(listing_id)
    Market.cancel_my_listing(listing_id)
  end

  rescue_from(RestClient::BadGateway) do |e|
    headers = e.http_headers
    set_cookie = headers[:set_cookie]
    unless set_cookie.nil?
      cookies = Utility.parse_cookies(set_cookie)
      if cookies.any? { |cookie| cookie.value == 'deleted' }
        Account::DEFAULT.refresh
        retry_job
      end
    end
    false
  end
end
