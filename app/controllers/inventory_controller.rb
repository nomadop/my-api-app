class InventoryController < ActionController::Base
  def assets
    render json: InventoryAsset.non_gems.non_sacks_of_gem.includes(:description, :market_asset, :order_histogram).as_json(
      only: [:id, :assetid, :amount],
      methods: [
        :marketable, :market_hash_name, :marketable_date, :listing_url,
        :price_per_goo_exclude_vat, :sell_order_count, :highest_buy_order, :buy_order_count,
        :lowest_sell_order_exclude_vat, :highest_buy_order_exclude_vat,
        :type, :goo_value,
      ]
    )
  end

  def show
    render layout: 'vue'
  end

  def reload
    Inventory.reload!
    redirect_to action: 'assets'
  end

  def sell_by_ppg
    assets = InventoryAsset.where(id: params[:asset_ids])
    assets.find_each { |asset| asset.sell_by_ppg(params[:sell_ppg]) }
    render json: { success: true }
  end
end
