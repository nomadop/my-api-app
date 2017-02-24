class Market
  class << self
    def load_asset(market_hash_name)
      response = RestClient.get("http://steamcommunity.com/market/listings/753/#{URI.encode(market_hash_name)}")
      html = response.body
      assets = Utility.match_json_var('g_rgAssets', html)
      asset = assets&.values&.[](0)&.values&.[](0)&.values&.[](0)
      asset_model = MarketAsset.find_or_create_by(classid: asset['classid'])
      item_nameid = /Market_LoadOrderSpread\( (\d+) \);/.match(html)&.[] 1
      asset_model.update(asset.except('id').merge(item_nameid: item_nameid))
      asset_model
    end

    def load_order_histogram(item_nameid)
      response = RestClient.get('http://steamcommunity.com/market/itemordershistogram', {
          params: {
              language: :english,
              currency: 23,
              item_nameid: item_nameid
          },
          proxy: 'http://127.0.0.1:8888'
      })
      result = JSON.parse(response.body)
      order_histogram = OrderHistogram.find_or_create_by(item_nameid: item_nameid)
      order_histogram.update(result.slice('highest_buy_order', 'lowest_sell_order', 'buy_order_graph', 'sell_order_graph'))
      order_histogram
    end
  end
end