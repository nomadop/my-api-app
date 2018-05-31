class AccountsController < ApplicationController
  def list
    render json: Account.order(:id).as_json(only: [:id, :bot_name])
  end
end
