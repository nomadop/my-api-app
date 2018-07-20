class InventoryController < ApplicationController
  def assets
    render json: InventoryAsset.non_gems.non_sacks_of_gem.includes(:description, :market_asset, :order_histogram).as_json(
      only: [:id, :assetid, :amount],
      methods: [
        :marketable, :market_hash_name, :marketable_date, :listing_url,
        :price_per_goo_exclude_vat, :sell_order_count, :highest_buy_order, :buy_order_count,
        :lowest_sell_order_exclude_vat, :highest_buy_order_exclude_vat,
        :type, :goo_value, :bot_name
      ]
    )
  end

  def show
    render layout: 'vue'
  end

  def reload
    Inventory.reload_all!
    redirect_to action: 'assets'
  end

  def sell_by_ppg
    assets = InventoryAsset.where(id: params[:asset_ids])
    assets.find_each { |asset| asset.sell_by_ppg(params[:sell_ppg]) }
    render json: { success: true }
  end

  def grind_into_goo
    assets = InventoryAsset.where(id: params[:asset_ids])
    assets.find_each(&:grind_into_goo)
    render json: { success: true }
  end

  def send_trade_offer
    target = Account.enabled.find(params[:target])
    InventoryAsset.where(id: params[:ids]).send_offer_to(target)
    render plain: 'success'
  end
end
