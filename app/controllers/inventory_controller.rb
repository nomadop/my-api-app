class InventoryController < ActionController::Base
  def assets
    render json: InventoryAsset.includes(:description, :market_asset, :order_histogram).as_json(
      only: [:amount],
      methods: [
        :marketable?, :market_hash_name, :marketable_date, :listing_url,
        :goo_value, :lowest_sell_order, :sell_order_count,
      ]
    )
  end

  def show
    render layout: 'vue'
  end
end
