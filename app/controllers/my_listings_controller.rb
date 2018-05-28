class MyListingsController < ActionController::Base
  def list
    render json: MyListing.includes(:market_asset, :order_histogram).as_json(
      only: [:listingid, :market_hash_name, :price, :listed_date, :confirming],
      methods: [
        :price_exclude_vat, :price_per_goo_exclude_vat,
        :lowest_sell_order, :lowest_sell_order_exclude_vat,
        :market_name, :market_fee_app, :name, :type,
      ]
    )
  end

  def show
    render layout: 'vue'
  end
end
