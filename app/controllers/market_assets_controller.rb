class MarketAssetsController < ApplicationController
  def orderable
    result = MarketAsset.orderable.without_active_buy_order
    result = result.limit(params[:limit]) if params[:limit]
    result = (params[:count] == 't') ? result.count : result.pluck(:classid)
    render json: result
  end
end
