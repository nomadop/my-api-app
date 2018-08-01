class BuyOrdersController < ApplicationController
  def import
    buy_orders = JSON.parse(request.raw_post)
    count = buy_orders.blank? ? 0 : BuyOrder.import(buy_orders, on_duplicate_key_ignore: {
      conflict_target: :buy_orderid,
    }).ids.count
    render json: { imported: count }
  end

  def list
    result = BuyOrder.active
    result = result.belongs(Account.search(params[:belongs])) if params[:belongs]
    result = result.count if params[:count] == 't'
    render json: result.as_json
  end
end
