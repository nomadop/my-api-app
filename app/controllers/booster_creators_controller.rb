class BoosterCreatorsController < ActionController::Base
  def refresh
    BoosterCreator.refresh_by_ppg_order
  end

  def creatable
    if params[:refresh]
      MyListing.reload_all!
      Inventory.reload_all!
      Account.load_all_booster_creators
    end
    ppg = params[:base_ppg] || 0.57
    limit = params[:limit] || 100
    render json: BoosterCreator.creatable(ppg: ppg.to_f, limit: limit.to_i).map(&:booster_pack_info)
  end

  def show
    render layout: 'vue'
  end

  def create_and_sell
    booster_creator.create_and_sell(account)
  end

  def create_and_unpack
    booster_creator.create_and_unpack(account)
  end

  def sell_all_assets
    account.nil? ? Inventory.reload_all! : Inventory.reload!(account)
    booster_creator.sell_all_assets(account)
  end

  private
  def booster_creator
    BoosterCreator.find_by(appid: params[:appid])
  end

  def account
    @account ||= Account.find_by(bot_name: params[:bot_name])
  end
end
