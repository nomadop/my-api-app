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
      app_asset = assets&.values&.[](0)
      asset = if app_asset.is_a?(Array)
                app_asset[0][0]
              else
                app_asset&.values&.[](0)&.values&.[](0)
              end
      return nil if asset.nil? or asset.empty?

      asset_model = MarketAsset.find_or_initialize_by(classid: asset['classid'])
      item_nameid = /Market_LoadOrderSpread\( (\d+) \);/.match(html)&.[] 1
      asset_model.update(asset.except('id').merge(item_nameid: item_nameid))
      asset_model
    rescue Exception => e
      puts assets
      raise e
    end

    def load_asset_by_url(url)
      option = {
          method: :get,
          url: url,
          proxy: 'http://localhost:8888',
      }
      response = RestClient::Request.execute(option)
      load_asset(response)
    end

    def load_asset_by_hash_name(market_hash_name)
      response = RestClient.get("http://steamcommunity.com/market/listings/753/#{URI.encode(market_hash_name)}")
      load_asset(response)
    end

    def load_order_histogram(item_nameid)
      option = {
          method: :get,
          url: 'http://steamcommunity.com/market/itemordershistogram',
          headers: {
              params: {
                  language: :english,
                  currency: 23,
                  item_nameid: item_nameid,
              }
          },
          proxy: 'http://localhost:1087/'
      }
      response = RestClient::Request.execute(option)
      result = JSON.parse(response.body)
      order_histogram = OrderHistogram.find_or_create_by(item_nameid: item_nameid)
      order_histogram.update(result.slice('highest_buy_order', 'lowest_sell_order', 'buy_order_graph', 'sell_order_graph'))
      order_histogram
    end

    def search(appid, start = 0, count = 10)
      response = RestClient.get('http://steamcommunity.com/market/search/render/', {
          params: {
              query: '',
              start: start,
              count: count,
              search_descriptions: 0,
              sort_column: 'default',
              sort_dir: 'desc',
              appid: 753,
              :'category_753_Game[]' => "tag_app_#{appid}",
          },
      })
      JSON.parse(response.body)
    end

    def handle_search_result(result, game_name = nil)
      return if result['total_count'] == 0

      doc = Nokogiri::HTML(result['results_html'])
      rows = doc.search('.market_listing_row_link')

      rows.each do |row|
        url = row.attr(:href)
        name = row.search('.market_listing_item_name')&.inner_text
        type = row.search('.market_listing_game_name')&.inner_text
        allows = game_name.nil? ? ALLOWED_ASSET_TYPE : ALLOWED_ASSET_TYPE.map { |type| "#{game_name} #{type}" }
        next if allows.none?(&type.method(:end_with?))

        if MarketAsset.where(market_name: name, type: type).empty?
          ApplicationJob.perform_unique(LoadMarketAssetJob, url)
        end
      end
    end

    def scan(appid)
      ScanMarketJob.perform_later(appid, 0, 100)
    end

    def request_my_listings(start, count)
      cookie = Authentication.cookie
      option = {
          method: :get,
          url: 'http://steamcommunity.com/market/mylistings/render/',
          headers: {
              :params => {
                  start: start,
                  count: count,
              },
              :Accept => 'text/javascript, text/html, application/xml, text/xml, */*',
              :'Accept-Encoding' => 'gzip, deflate, sdch',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => 'http://steamcommunity.com/market/',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Prototype-Version' => 1.7,
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      Authentication.update_cookie(response)
      JSON.parse(response.body)
    end

    def handle_my_listing_result(result)
      assets = result['assets']['753']['6'].values
      MyListing.destroy_all
      MyListing.create(assets.map do |asset|
        {
            listingid: asset['id'],
            classid: asset['classid'],
            market_hash_name: asset['market_hash_name'],
        }
      end)
    end

    def load_my_listings
      LoadMyListingsJob.perform_later(0, 100)
    end

    def create_buy_order(market_hash_name, price, quantity)
      cookie = Authentication.cookie
      session_id = Authentication.session_id

      option = {
          method: :post,
          url: 'https://steamcommunity.com/market/createbuyorder/',
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => "http://steamcommunity.com/market/listings/753/#{URI.encode(market_hash_name)}",
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          payload: {
              sessionid: session_id,
              currency: 23,
              appid: 753,
              market_hash_name: market_hash_name,
              price_total: price * quantity,
              quantity: quantity
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      Authentication.update_cookie(response)
      JSON.parse(response.body)
    end

    def get_buy_order_status(buy_order_id)
      cookie = Authentication.cookie
      session_id = Authentication.session_id

      option = {
          method: :get,
          url: 'http://steamcommunity.com/market/getbuyorderstatus/',
          headers: {
              :params => {
                  sessionid: session_id,
                  buy_orderid: buy_order_id,
              },
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => 'http://steamcommunity.com/market/',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      Authentication.update_cookie(response)
      JSON.parse(response.body)
    end

    def cancel_buy_order(buy_order_id)
      cookie = Authentication.cookie
      session_id = Authentication.session_id

      option = {
          method: :post,
          url: 'http://steamcommunity.com/market/cancelbuyorder/',
          headers: {
              :Accept => 'text/javascript, text/html, application/xml, text/xml, */*',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => 'http://steamcommunity.com/market/',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          payload: {
              sessionid: session_id,
              buy_orderid: buy_order_id,
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      Authentication.update_cookie(response)
      JSON.parse(response.body)
    end
  end
end