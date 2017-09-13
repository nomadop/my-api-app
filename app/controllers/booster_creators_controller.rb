class BoosterCreatorsController < ActionController::Base
  def refresh
    BoosterCreator.refresh_by_ppg_order
  end

  def creatable
    MyListing.reload!
    ppg = params[:base_ppg] || 0.57
    limit = params[:limit] || 100
    render json: BoosterCreator.creatable(ppg: ppg.to_f, limit: limit.to_i).map(&:booster_pack_info)
  end

  def show
    render layout: 'vue'
  end

  def create_and_sell
    booster_creator = BoosterCreator.find_by(appid: params[:appid])
    booster_creator.create_and_sell
  end
end
