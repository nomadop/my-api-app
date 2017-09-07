class BoosterCreatorsController < ActionController::Base
  def refresh
    BoosterCreator.refresh_by_ppg_order
  end

  def creatable
    MyListing.reload!
    render json: BoosterCreator.creatable(ppg: 0.57).map(&:booster_pack_info)
  end

  def show
    render layout: 'vue'
  end

  def create_and_sell
    data = JSON.parse(request.body.read)
    booster_creator = BoosterCreator.find_by(appid: data['appid'])
    booster_creator.create_and_sell
  end
end
