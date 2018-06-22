class Market
  ALLOWED_ASSET_TYPE = [
    'Booster Pack', 'Trading Card', 'Foil Trading Card',
    'Emoticon', 'Rare Emoticon', 'Uncommon Emoticon',
    'Profile Background', 'Rare Profile Background', 'Uncommon Profile Background',
  ]

  class << self
    def get_url(market_hash_name)
      "http://steamcommunity.com/market/listings/753/#{URI.encode_www_form_component(market_hash_name)}"
    end

    def request_asset(url, with_authentication = false)
      option = {
        method: :get,
        url: url,
        proxy: 'socks5://localhost:9150/',
      }
      if with_authentication
        cookie = Authentication.cookie
        option[:headers] = {
          :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          :'Accept-Encoding' => 'gzip, deflate, sdch',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
          :'Cookie' => cookie,
          :'Host' => 'steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Upgrade-Insecure-Requests' => 1,
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
        }
        option[:proxy] = 'http://localhost:8888'
        option[:ssl_ca_file] = 'config/certs/ca_certificate.pem'
      end
      response = with_authentication ? RestClient::Request.execute(option) : TOR.request(option)
      response.body
    end

    def handle_sell_history(classid, asset_body)
      sell_histories_json = Utility.match_json_var('line1', asset_body)
      return if sell_histories_json.blank?

      sell_histories = sell_histories_json.map do |history|
        { classid: classid, datetime: history[0], price: (history[1] * 100).round(1), amount: history[2] }
      end

      SellHistory.transaction do
        SellHistory.where(classid: classid).delete_all
        SellHistory.import(sell_histories)
      end
    end

    def load_asset(html)
      assets = Utility.match_json_var('g_rgAssets', html)
      return nil if assets.blank?
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
      handle_sell_history(asset_model.classid, html)
      asset_model
    rescue Exception => e
      puts assets
      raise e
    end

    def load_asset_by_url(url)
      html = request_asset(url)
      load_asset(html)
    end

    def load_asset_by_hash_name(market_hash_name)
      html = request_asset(get_url(market_hash_name))
      load_asset(html)
    end

    def load_order_histogram(item_nameid, proxy = true)
      order_histogram = OrderHistogram.find_by(item_nameid: item_nameid)
      return order_histogram if order_histogram && order_histogram.updated_at > 5.minutes.ago
      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/itemordershistogram',
        headers: {
          params: {
            language: :english,
            currency: 23,
            item_nameid: item_nameid,
          }
        },
      }
      unless proxy
        option[:proxy] = 'http://localhost:8888'
        option[:ssl_ca_file] = 'config/certs/ca_certificate.pem'
      end
      response = proxy ? TOR.request(option) : RestClient::Request.execute(option)
      result = JSON.parse(response.body)
      raise "load order histogram failed with code #{result['success']}" unless result['success'] == 1

      order_histogram = OrderHistogram.find_or_create_by(item_nameid: item_nameid)
      order_histogram.update(
        highest_buy_order: result['highest_buy_order'],
        lowest_sell_order: result['lowest_sell_order'],
        buy_order_graph: result['buy_order_graph'],
        sell_order_graph: result['sell_order_graph'],
        cached_lowest_buy: [order_histogram.cached_lowest_buy, result['highest_buy_order']].map(&Utility.method(:int_or_inf)).min,
        cached_highest_buy: [order_histogram.cached_highest_buy, result['highest_buy_order']].map(&Utility.method(:int_or_zero)).max,
        cached_lowest_sell: [order_histogram.cached_lowest_sell, result['lowest_sell_order']].map(&Utility.method(:int_or_inf)).min,
        cached_highest_sell: [order_histogram.cached_highest_sell, result['lowest_sell_order']].map(&Utility.method(:int_or_zero)).max,
      )
      OrderHistogramHistory.create(result.slice('item_nameid', 'highest_buy_order', 'lowest_sell_order'))
    end

    def search(appid, start = 0, count = 10)
      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/search/render/',
        headers: {
          :params => {
            query: '',
            start: start,
            count: count,
            search_descriptions: 0,
            sort_column: 'default',
            sort_dir: 'desc',
            appid: 753,
            :'category_753_Game[]' => "tag_app_#{appid}",
          },
        },
        proxy: 'http://localhost:8888/',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    rescue RestClient::TooManyRequests
      JobConcurrence.tor_newnym
      JobConcurrence.wait_for('TorNewnymJob')
      search(appid, start, count)
    end

    def search_by_query(query, start = 0, count = 10)
      response = RestClient.get('http://steamcommunity.com/market/search/render/', {
        params: {
          query: query,
          start: start,
          count: count,
          search_descriptions: 0,
          sort_column: 'default',
          sort_dir: 'desc',
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

    def scan_by_query(query)
      ScanMarketByQueryJob.perform_later(query, 0, 100)
    end

    def request_my_listings(start, count, account = Account::DEFAULT)
      cookie = account.cookie
      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/mylistings/render/',
        headers: {
          :params => {
            start: start,
            count: count,
          },
          :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          :'Accept-Encoding' => 'gzip, deflate, sdch',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Cookie' => cookie,
          :'Host' => 'steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Referer' => 'http://steamcommunity.com/market/',
          :'Upgrade-Insecure-Requests' => 1,
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      result = JSON.parse(response.body)
      result['total_count'] == 0 && result['start'] > 0 ? request_my_listings(start, count, account) : result
    rescue RestClient::BadRequest
      account.refresh
      request_my_listings(start, count, account = Account::DEFAULT)
    end

    def handle_my_listing_row(row, account = Account::DEFAULT, confirming = false)
      listingid = row.attr(:id).match(/mylisting_(?<id>\d+)/)[:id]
      name_link = row.search('.market_listing_item_name_link').first
      market_hash_name = URI.decode(name_link.attr(:href).split('/').last)
      price_text = row.search('.market_listing_price > span > span:eq(1)').text.strip
      price_text_match = price_text.match(/¥\s+(?<price>\d+(\.\d+)?)/)
      price = price_text_match && price_text_match[:price].to_f * 100
      listed_date = row.search('.market_listing_listed_date').text.strip
      { listingid: listingid, market_hash_name: market_hash_name, price: price, listed_date: listed_date, confirming: confirming, account_id: account.id }
    end

    def handle_my_listing_result(result, account = Account::DEFAULT)
      doc = Nokogiri::HTML(result['results_html'])
      rows = doc.search('.market_listing_row')
      my_listings = rows.map { |row| handle_my_listing_row(row, account) }
      MyListing.import(my_listings)
    end

    def load_confirming_listings(account = Account::DEFAULT)
      doc = Nokogiri::HTML(Market.request_market(account))
      listing_section = doc.search('.my_listing_section').find do |section|
        section.search('.my_market_header_active').first&.text === '我的等待确认的上架物品'
      end
      return if listing_section.nil?
      rows = listing_section.search('.market_listing_row')
      my_listings = rows.map { |row| handle_my_listing_row(row, account, true) }
      MyListing.import(my_listings)
    end

    def load_my_listings
      LoadMyListingsJob.perform_later(0, 100)
    end

    def create_buy_order(market_hash_name, price, quantity, account_id)
      account = Account.find(account_id)
      cookie = account.cookie
      session_id = account.session_id

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
          :'Origin' => 'https://steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Referer' => "https://steamcommunity.com/market/listings/753/#{URI.encode(market_hash_name)}",
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
      JSON.parse(response.body)
    end

    def get_buy_order_status(account, buy_order_id)
      cookie = account.cookie
      session_id = account.session_id

      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/getbuyorderstatus/',
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
          :'Referer' => 'https://steamcommunity.com/market/',
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def cancel_buy_order(account, buy_order_id)
      cookie = account.cookie
      session_id = account.session_id

      option = {
        method: :post,
        url: 'https://steamcommunity.com/market/cancelbuyorder/',
        headers: {
          :Accept => 'text/javascript, text/html, application/xml, text/xml, */*',
          :'Accept-Encoding' => 'gzip, deflate',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Content-type' => 'application/x-www-form-urlencoded; charset=UTF-8',
          :'Cookie' => cookie,
          :'Host' => 'steamcommunity.com',
          :'Origin' => 'https://steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Referer' => 'https://steamcommunity.com/market/',
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
      JSON.parse(response.body)
    end

    def cancel_my_listing(account, listingid)
      cookie = account.cookie
      session_id = account.session_id

      option = {
        method: :post,
        url: "https://steamcommunity.com/market/removelisting/#{listingid}",
        headers: {
          :Accept => 'text/javascript, text/html, application/xml, text/xml, */*',
          :'Accept-Encoding' => 'gzip, deflate',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Content-type' => 'application/x-www-form-urlencoded; charset=UTF-8',
          :'Cookie' => cookie,
          :'Host' => 'steamcommunity.com',
          :'Origin' => 'https://steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Referer' => 'https://steamcommunity.com/market/',
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
        },
        payload: {
          sessionid: session_id,
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    end

    def quick_buy_schedule(ppg, slices)
      slice_size = 3000
      assets = MarketAsset.sell_ppg_order.first(slices * slice_size)
      assets.each_slice(slice_size).with_index(0) do |asset_slice, index|
        wait = (index * 2).hours
        asset_slice.each { |asset| asset.quick_buy_later(ppg, wait: wait) }
      end
    end

    def quick_buy_buyable(ppg)
      MarketAsset.buyable.quick_buy_later(ppg)
    end

    def request_market(account = Account::DEFAULT)
      cookie = account.cookie

      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/',
        headers: {
          :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          :'Accept-Encoding' => 'gzip, deflate, sdch',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Cookie' => cookie,
          :'Host' => 'steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      account.update_cookie(response)
      response.body
    end

    def send_trade(account, profile, steamid, offer, message = '')
      cookie = account.cookie
      session_id = account.session_id

      option = {
        method: :post,
        url: 'https://steamcommunity.com/tradeoffer/new/send',
        headers: {
          :Accept => '*/*',
          :'Accept-Encoding' => 'gzip, deflate, br',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
          :'Cookie' => cookie,
          :'Host' => 'steamcommunity.com',
          :'Origin' => 'https://steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Referer' => "https://steamcommunity.com/tradeoffer/new/?partner=#{profile}",
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
        },
        payload: {
          sessionid: session_id,
          serverid: 1,
          partner: steamid,
          tradeoffermessage: message,
          json_tradeoffer: offer,
          captcha: '',
          trade_offer_create_params: {},
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    end

    def request_order_activity(item_nameid)
      option = {
        method: :get,
        url: 'http://steamcommunity.com/market/itemordersactivity',
        headers: {
          params: {
            country: :CN,
            language: :schinese,
            currency: 23,
            item_nameid: item_nameid,
            two_factor: 0,
          }
        },
        proxy: 'http://localhost:8888/'
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def handle_order_activity(item_nameid, result)
      return unless result['success'] == 1

      activities = result['activity']
      activities.map! do |activity|
        doc = Nokogiri::HTML(activity)
        content = doc.inner_text.strip
        user_names = doc.search('.market_ticker_name').map(&:inner_text)
        user_avatars = doc.search('.market_ticker_avatar img').map { |img| img.attr(:src) }
        price_text_match = content.match(/¥\s+(?<price>\d+(\.\d+)?)/)
        price = price_text_match && price_text_match[:price].to_f * 100
        {
          item_nameid: item_nameid,
          content: content,
          user1_name: user_names[0],
          user1_avatar: user_avatars[0].match(/\/([^\/.]+)\.jpg/)[1],
          user2_name: user_names[1],
          user2_avatar: user_avatars[1] && user_avatars[1].match(/\/([^\/.]+)\.jpg/)[1],
          price: price
        }
      end
      OrderActivity.import(activities, on_duplicate_key_ignore: {
        conflict_target: :content,
      })
    end

    def pull_order_activity(item_nameid)
      result = request_order_activity(item_nameid)
      handle_order_activity(item_nameid, result)
    end

    def request_my_history(start, count, account_id = 1)
      account = Account.find(account_id)
      cookie = account.cookie
      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/myhistory/render/',
        headers: {
          :params => {
            start: start,
            count: count,
          },
          :Accept => '*/*',
          :'Accept-Encoding' => 'gzip, deflate, sdch',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Cookie' => cookie,
          :'Host' => 'steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Referer' => 'http://steamcommunity.com/market/',
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
          :'X-Requested-With' => 'XMLHttpRequest',
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      result = JSON.parse(response.body)
      if result['total_count'].nil?
        account.refresh
        request_my_history(start, count)
      else
        result
      end
    end

    def handle_my_history_result(result, account_id = 1)
      assets = result['assets']['753']['6'].values
      doc = Nokogiri::HTML(result['results_html'])
      rows = doc.search('.market_listing_row.market_recent_listing_row')
      my_history = rows.map do |row|
        row_id = row.attr(:id)
        history_id = row_id.match(/history_row_(?<id>.+)/)[:id]
        who_acted_with = row.search('.market_listing_right_cell.market_listing_whoactedwith').inner_text.strip.gsub(/[\t\r\n]/, '')
        listed_date = row.search('.market_listing_listed_date_combined').inner_text.strip
        price_text = row.search('.market_listing_price').text.strip
        price_text_match = price_text.match(/¥\s+(?<price>\d+(\.\d+)?)/)
        price = price_text_match && price_text_match[:price].to_f * 100
        market_listing_name = row.search('.market_listing_item_name_block .market_listing_item_name').inner_text
        market_listing_name = '一袋宝珠' if market_listing_name =~ /\d+ 一袋宝珠/
        market_listing_name = '一袋宝石' if market_listing_name =~ /\d+ 一袋宝石/
        asset = assets.find { |asset| asset['market_name'] == market_listing_name }

        {
          account_id: account_id,
          history_id: history_id,
          who_acted_with: who_acted_with,
          listed_date: listed_date,
          price: price,
          market_listing_name: market_listing_name,
          classid: asset['classid'],
          market_hash_name: asset['market_hash_name'],
        }
      end
      MyHistory.import(my_history, on_duplicate_key_ignore: {
        conflict_target: :history_id,
      })
    end

    def scan_my_histories(account_id = 1)
      LoadMyHistoriesJob.perform_later(0, 100, account_id)
    end

    def eligibility_check(account)
      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/eligibilitycheck/',
        headers: {
          :params => {
            goto: 0,
          },
          :Accept => 'text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, image/apng, */*;q=0.8',
          :'Accept-Encoding' => 'gzip, deflate',
          :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
          :'Cache-Control' => 'no-cache',
          :'Connection' => 'keep-alive',
          :'Cookie' => account.cookie,
          :'Host' => 'steamcommunity.com',
          :'Pragma' => 'no-cache',
          :'Upgrade-Insecure-Requests' => 1,
          :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      account.update_cookie(response)
    end

    def load_price_overview(market_hash_name, proxy = true)
      option = {
        method: :get,
        url: 'https://steamcommunity.com/market/priceoverview/',
        headers: {
          params: {
            appid: 753,
            country: 'CN',
            currency: 23,
            market_hash_name: market_hash_name,
          }
        },
      }
      unless proxy
        option[:proxy] = 'http://localhost:8888'
        option[:ssl_ca_file] = 'config/certs/ca_certificate.pem'
      end
      response = proxy ? TOR.request(option) : RestClient::Request.execute(option)
      result = JSON.parse(response.body)
      if result['success']
        MarketAsset.find_by(market_hash_name: market_hash_name).update(sell_volume: result['volume'] || 0)
      end
    end
  end
end
