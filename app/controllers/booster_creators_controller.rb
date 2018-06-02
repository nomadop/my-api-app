class BoosterCreatorsController < ActionController::Base
  def refresh
    BoosterCreator.refresh_by_ppg_order
  end

  def creatable
    if params[:refresh]
      Account.delegate_all([
        { class_name: :MyListing, method: :reload! },
        { class_name: :MyListing, method: :reload_confirming! },
        { class_name: :Inventory, method: :reload! },
        { class_name: :Account, method: :load_booster_creators },
      ])
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
    @account ||= Account.enabled.find_by(bot_name: params[:bot_name])
  end
end
