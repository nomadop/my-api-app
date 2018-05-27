class InventoryController < ActionController::Base
  def assets
    render json: InventoryAsset.non_gems.includes(:description, :market_asset, :order_histogram).as_json(
      only: [:id, :assetid, :amount],
      methods: [
        :marketable, :market_hash_name, :marketable_date, :listing_url,
        :lowest_sell_order, :sell_order_count, :highest_buy_order, :buy_order_count,
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
    render :assets
  end
end
