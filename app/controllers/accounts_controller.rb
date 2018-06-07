class AccountsController < ApplicationController
  def list
    render json: Account.order(:id).as_json(only: [:id, :account_id, :bot_name, :status])
  end

  def asf_command
    account = Account.find(params[:id])
    render json: account.asf(params[:command])
  end
end
