class AccountHistoriesController < ApplicationController
  def all
    account_histories = AccountHistory
    account_histories = account_histories.since(Time.at(params[:from_date].to_i)) unless params[:from_date].nil?
    account_histories = account_histories.non_market unless params[:include_market] == 'true'
    render json: account_histories.includes(:account).order(date: :desc).as_json(
      except: [:account_id, :created_at, :updated_at],
      include: {
        account: { only: [:id, :bot_name] }
      },
      methods: [:formatted_date],
    )
  end

  def show
    render layout: 'vue'
  end
end
