class AccountsController < ApplicationController
  def list
    render json: Account.order(:id).as_json(only: [:id, :account_id, :bot_name, :status])
  end
end
