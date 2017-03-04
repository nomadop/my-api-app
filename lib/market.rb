class Market
  ALLOWED_ASSET_TYPE = [
      'Booster Pack', 'Trading Card', 'Foil Trading Card',
      'Emoticon', 'Rare Emoticon', 'Uncommon Emoticon',
      'Profile Background', 'Rare Profile Background', 'Uncommon Profile Background',
  ]

  class << self
    def load_asset(response)
      html = response.body
      assets = Utility.match_json_var('g_rgAssets', html)
      asset = assets&.values&.[](0)&.values&.[](0)&.values&.[](0)
      return nil if asset.nil? or asset.empty?

      asset_model = MarketAsset.find_or_initialize_by(classid: asset['classid'])
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
              query: URI.encode(query),
              start: start,
              count: count,
              search_descriptions: 0,
              sort_column: 'default',
              sort_dir: 'desc'
          },
      })
      JSON.parse(response.body)
    end

    def handle_search_result(result)
      doc = Nokogiri::HTML(result['results_html'])
      rows = doc.search('.market_listing_row_link')

      rows.each do |row|
        url = row.attr(:href)
        name = row.search('.market_listing_item_name')&.inner_text
        type = row.search('.market_listing_game_name')&.inner_text
        next if ALLOWED_ASSET_TYPE.none?(&type.method(:end_with?))

        if MarketAsset.where(market_name: name, type: type).empty?
          ApplicationJob.perform_unique(LoadMarketAssetJob, url: url)
        end
      end
    end

    def scan(query)
      ScanMarketJob.perform_later(query, 0, 100)
    end
  end
end