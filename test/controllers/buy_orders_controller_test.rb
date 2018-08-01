require 'test_helper'

class BuyOrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get import" do
    get buy_orders_import_url
    assert_response :success
  end

end
