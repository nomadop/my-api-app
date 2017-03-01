class Market
  class << self
    def load_asset(response)
      html = response.body
      assets = Utility.match_json_var('g_rgAssets', html)
      asset = assets&.values&.[](0)&.values&.[](0)&.values&.[](0)
      return nil if asset.nil? or asset.empty?

      asset_model = MarketAsset.find_or_create_by(classid: asset['classid'])
      item_nameid = /Market_LoadOrderSpread\( (\d+) \);/.match(html)&.[] 1
      asset_model.update(asset.except('id').merge(item_nameid: item_nameid))
      asset_model
    end

    def load_asset_by_url(url)
      response = RestClient.get(url)
      load_asset(response)
    end

    def load_asset_by_hash_name(market_hash_name)
      response = RestClient.get("http://steamcommunity.com/market/listings/753/#{URI.encode(market_hash_name)}")
      load_asset(response)
    end

    def load_order_histogram(item_nameid)
      response = RestClient.get('http://steamcommunity.com/market/itemordershistogram', {
          params: {
              language: :english,
              currency: 23,
              item_nameid: item_nameid
          },
      })
      result = JSON.parse(response.body)
      order_histogram = OrderHistogram.find_or_create_by(item_nameid: item_nameid)
      order_histogram.update(result.slice('highest_buy_order', 'lowest_sell_order', 'buy_order_graph', 'sell_order_graph'))
      order_histogram
    end

    def search(query, start = 0, count = 10)
      response = RestClient.get('http://steamcommunity.com/market/search/render/', {
          params: {
              query: query,
              start: start,
              count: count,
              search_descriptions: 0,
              sort_column: 'default',
              sort_dir: 'desc'
          },
      })
      JSON.parse(response.body)
    end

    def save_search_result(result)
      doc = Nokogiri::HTML(result['results_html'])
      rows = doc.search('.market_listing_row_link')

      MarketSearchResult.transaction do
        rows.each do |row|
          listing_url = row.attr(:href)
          item_name = row.search('.market_listing_item_name')&.inner_text
          game_name = row.search('.market_listing_game_name')&.inner_text

          model = MarketSearchResult.find_or_initialize_by(listing_url: listing_url)
          model.update(item_name: item_name, game_name: game_name)
        end
      end
    end
  end
end