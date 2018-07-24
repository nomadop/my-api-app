class TorController < ApplicationController
  skip_before_action :require_login

  def reset_instance_pool
    TOR.reset_instance_pool
  end
end
