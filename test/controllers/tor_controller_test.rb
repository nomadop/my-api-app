require 'test_helper'

class TorControllerTest < ActionDispatch::IntegrationTest
  test "should get reset" do
    get tor_reset_url
    assert_response :success
  end

end
