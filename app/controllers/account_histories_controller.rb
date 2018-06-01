class AccountHistoriesController < ActionController::Base
  def all
    account_histories = AccountHistory
    account_histories = account_histories.since(Time.at(params[:from_date].to_i)) unless params[:from_date].nil?
    render json: account_histories.includes(:account).non_market.order(date: :desc).as_json(
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
