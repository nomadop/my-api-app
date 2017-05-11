class Inventory
  class << self
    def reload
      steam_id = Authentication.steam_id
      cookie = Authentication.cookie
      option = {
          method: :get,
          url: "http://steamcommunity.com/inventory/#{steam_id}/753/6?l=schinese",
          headers: {
              :Accept => '*/*',
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
      Authentication.update_cookie(response)

      response.code == 200 ? JSON.parse(response.body) : {
          'assets' => [],
          'descriptions' => [],
      }
    rescue RestClient::Forbidden => _
      Authentication.refresh
      reload
    end

    def reload!
      result = reload
      assets = result['assets']
      InventoryAsset.transaction do
        InventoryAsset.truncate
        InventoryAsset.import(assets)
      end
      descriptions = result['descriptions']
      InventoryDescription.import(descriptions, on_duplicate_key_update: {
          conflict_target: [:classid, :instanceid],
          columns: [:actions, :marketable, :owner_actions, :tradable, :owner_descriptions],
      })
    end

    def auto_sell_and_grind
      Inventory.reload!
      InventoryAsset.non_sacks_of_gem.includes(:market_asset).auto_sell_and_grind_later
    end

    def auto_sell_and_grind_marketable
      Inventory.reload!
      InventoryAsset.non_sacks_of_gem.marketable.includes(:market_asset).auto_sell_and_grind_later
    end

    def request_booster_creators
      cookie = Authentication.cookie
      option = {
          method: :get,
          url: 'http://steamcommunity.com/tradingcards/boostercreator/',
          headers: {
              :Accept => '*/*',
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
      Authentication.update_cookie(response)
      regexp = /CBoosterCreatorPage.Init\(\s+(.*),\s+parseFloat/
      JSON.parse(regexp.match(response.body)[1])
    end

    def load_booster_creators
      boosters = request_booster_creators
      BoosterCreator.transaction do
        boosters.each do |booster|
          model = BoosterCreator.find_or_initialize_by(appid: booster['appid'])
          booster['name'] = Utility.unescapeHTML(booster['name'])
          model.update(booster)
        end
      end
    end

    def total_goo_value
      InventoryAsset.joins(:market_asset).sum(:goo_value)
    end

    def goo_value_by_marketable_date
      group_sql = <<-SQL.strip_heredoc
              to_char(
                to_timestamp(
                  substring(
                    inventory_descriptions.owner_descriptions->0->>'value' from '\\d+'
                  )::int
                ), 
                'YYYY-MM-DD'
              )
      SQL
      InventoryAsset
          .joins(:description, :market_asset)
          .group(group_sql)
          .sum('market_assets.goo_value')
    end

    def gem_amount_info
      query_result = InventoryAsset.gems
                         .joins(:description)
                         .group('inventory_descriptions.tradable')
                         .sum('CAST(amount AS int)')
      {
          total: query_result[0] + query_result[1],
          tradable: query_result[1],
          untradable: query_result[0],
      }
    end

    def gem_amount_by_marketable_date
      group_sql = <<-SQL.strip_heredoc
              to_char(
                to_timestamp(
                  substring(
                    inventory_descriptions.owner_descriptions->0->>'value' from '\\d+'
                  )::int
                ), 
                'YYYY-MM-DD'
              )
      SQL
      InventoryAsset.gems
          .joins(:description)
          .group(group_sql)
          .sum('amount::int')
    end

    def create_booster(appid, series)
      cookie = Authentication.cookie
      sessionid = Authentication.session_id

      option = {
          method: :post,
          url: 'http://steamcommunity.com/tradingcards/ajaxcreatebooster/',
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => 'http://steamcommunity.com/tradingcards/boostercreator/',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          payload: {
              sessionid: sessionid,
              appid: appid,
              series: series,
              tradability_preference: 1,
          },
          proxy: 'http://127.0.0.1:8888',
      }
      RestClient::Request.execute(option)
    rescue RestClient::Forbidden => e
      Authentication.refresh
      raise e
    end

    def sell(assetid, price, amount)
      account = Authentication.account
      cookie = Authentication.cookie
      sessionid = Authentication.session_id

      option = {
          method: :post,
          url: 'https://steamcommunity.com/market/sellitem/',
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
              :'Referer' => "http://steamcommunity.com/id/#{account}/inventory/",
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          payload: {
              sessionid: sessionid,
              appid: 753,
              contextid: 6,
              assetid: assetid,
              amount: amount,
              price: price,
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    end

    def unpack_booster(assetid)
      account = Authentication.account
      cookie = Authentication.cookie
      sessionid = Authentication.session_id

      option = {
          method: :post,
          url: "http://steamcommunity.com/id/#{account}/ajaxunpackbooster/",
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => "http://steamcommunity.com/id/#{account}/inventory/",
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          payload: {
              sessionid: sessionid,
              appid: 753,
              communityitemid: assetid,
          },
          proxy: 'http://127.0.0.1:8888',
      }
      RestClient::Request.execute(option)
    rescue RestClient::Forbidden => e
      Authentication.refresh
      raise e
    end
  end
end
