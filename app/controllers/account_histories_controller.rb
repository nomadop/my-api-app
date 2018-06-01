class AccountHistoriesController < ActionController::Base
  def all
    render json: AccountHistory.includes(:account).non_market.order(date: :desc).as_json(
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
