class MyListingsController < ActionController::Base
  def list
    render json: MyListing.includes(:market_asset, :order_histogram, :account, :booster_creator,).as_json(
      only: [:listingid, :market_hash_name, :price, :listed_date, :confirming],
      methods: [
        :price_exclude_vat, :price_per_goo_exclude_vat,
        :lowest_sell_order, :lowest_sell_order_exclude_vat,
        :market_name, :market_fee_app, :name, :type,
        :bot_name, :booster_creator_cost,
      ]
    )
  end

  def show
    render layout: 'vue'
  end

  def reload
    MyListing.reload_all!
    redirect_to action: 'list'
  end

  def reload_confirming
    MyListing.reload_all_confirming!
    redirect_to action: 'list'
  end
end
