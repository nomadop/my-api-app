require 'test_helper'

class OrderHistogramsControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get order_histograms_list_url
    assert_response :success
  end

end
