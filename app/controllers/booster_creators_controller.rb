class BoosterCreatorsController < ActionController::Base
  def refresh
    BoosterCreator.refresh_by_ppg_order
  end

  def creatable
    if params[:refresh]
      MyListing.reload!
      Inventory.reload!
      Account::DEFAULT.load_booster_creators
    end
    ppg = params[:base_ppg] || 0.57
    limit = params[:limit] || 100
    render json: BoosterCreator.creatable(ppg: ppg.to_f, limit: limit.to_i).map(&:booster_pack_info)
  end

  def show
    render layout: 'vue'
  end

  def create_and_sell
    booster_creator.create_and_sell
  end

  def create_and_unpack
    booster_creator.create_and_unpack
  end

  def sell_all_assets
    Inventory.reload!
    booster_creator.sell_all_assets
  end

  private
  def booster_creator
    BoosterCreator.find_by(appid: params[:appid])
  end
end
