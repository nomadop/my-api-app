class Inventory
  class << self
    def reload(account)
      account_id = account.account_id
      cookie = account.cookie
      option = {
          method: :get,
          url: "https://steamcommunity.com/inventory/#{account_id}/753/6?l=schinese",
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
      account.update_cookie(response)

      response.code == 200 ? JSON.parse(response.body) : {
          'assets' => [],
          'descriptions' => [],
      }
    rescue RestClient::Forbidden => _
      account.refresh
      reload(account)
    rescue RestClient::InternalServerError => _
      reload(account)
    end

    def reload!(account = Account::DEFAULT)
      account = Account.find(account) unless account.is_a?(Account)
      result = reload(account)
      assets = result['assets']
      return if assets.nil?
      assets.each { |asset| asset['account_id'] = account.id }
      InventoryAsset.transaction do
        account.inventory_assets.delete_all(:delete_all)
        InventoryAsset.import(assets)
      end
      descriptions = result['descriptions']
      InventoryDescription.transaction do
        descriptions.each do |description|
          model = InventoryDescription.find_or_initialize_by(
              classid: description['classid'],
              instanceid: description['instanceid']
          )
          model.update(description)
        end
      end
      account.update(tradable_goo_amount: account.inventory_assets.gems.tradable.sum('CAST(amount AS int)'))
    end

    def reload_all!(wait = true)
      InventoryAsset.truncate
      Account.delegate_all({class_name: :Inventory, method: :reload!}, wait)
    end

    def auto_sell_and_grind(account = Account::DEFAULT)
      JobConcurrence.start do
        accounts = account.nil? ? Account.enabled : [account]
        accounts.flat_map do |acc|
          acc.inventory_assets.reload.non_gems.non_sacks_of_gem.includes(:market_asset).auto_sell_and_grind_later
        end
      end
    end

    def auto_sell_and_grind_marketable(account = Account::DEFAULT)
      JobConcurrence.start do
        accounts = account.nil? ? Account.enabled : [account]
        accounts.flat_map do |acc|
          acc.inventory_assets.reload.non_gems.non_sacks_of_gem.marketable.includes(:market_asset).auto_sell_and_grind_later
        end
      end
    end

    def request_booster_creators(account)
      cookie = account.cookie
      option = {
          method: :get,
          url: 'https://steamcommunity.com/tradingcards/boostercreator/',
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
      regexp = /CBoosterCreatorPage.Init\(\s+(.*),\s+parseFloat/
      JSON.parse(regexp.match(response.body)[1])
    end

    def load_booster_creators(account = Account::DEFAULT)
      boosters = request_booster_creators(account)
      booster_creators = boosters.map do |booster|
        booster['name'] = Utility.unescapeHTML(booster['name'])
        booster
      end
      BoosterCreator.import(booster_creators, on_duplicate_key_ignore: true)
      account_booster_creators = boosters.map do |booster|
        {
            appid: booster['appid'],
            account_id: account.id,
            unavailable: booster['unavailable'],
            available_at_time: booster['available_at_time'],
        }
      end
      AccountBoosterCreator.transaction do
        account.account_booster_creators.delete_all(:delete_all)
        AccountBoosterCreator.import(account_booster_creators)
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

    def gem_amount_info(account = nil)
      inventory_assets = account.nil? ? InventoryAsset : account.inventory_assets
      query_result = inventory_assets.gems.joins(:description).group('inventory_descriptions.tradable').sum('CAST(amount AS int)')
      total = query_result[0] || 0
      tradable = query_result[1] || 0
      {
          total: total + tradable,
          tradable: tradable,
          untradable: total,
      }
    end

    def gem_amount_all
      results = Account.enabled.map { |account| [account.bot_name, gem_amount_info(account)] }
      Hash[results.sort]
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
          .order(group_sql)
          .sum('amount::int')
    end

    def create_booster(appid, series, account = Account::DEFAULT)
      cookie = account.cookie
      sessionid = account.session_id

      option = {
          method: :post,
          url: 'https://steamcommunity.com/tradingcards/ajaxcreatebooster/',
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'https://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => 'https://steamcommunity.com/tradingcards/boostercreator/',
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
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    rescue RestClient::Forbidden
      account.refresh
      create_booster(appid, series, account)
    end

    def sell(assetid, price, amount, account = Account::DEFAULT)
      account_name = account.account_name
      cookie = account.cookie
      sessionid = account.session_id

      option = {
          method: :post,
          url: 'https://steamcommunity.com/market/sellitem/',
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.9,en;q=0.8,ja;q=0.7,zh-TW;q=0.6',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'https://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => "https://steamcommunity.com/id/#{account_name}/inventory/",
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

    def unpack_booster(assetid, account = Account::DEFAULT)
      account_name = account.account_name
      account_id = account.account_id
      cookie = account.cookie
      sessionid = account.session_id

      url = account_name.blank? ?
          "https://steamcommunity.com/profiles/#{account_id}/ajaxunpackbooster/" :
          "https://steamcommunity.com/id/#{account_name}/ajaxunpackbooster/"
      referer = account_name.blank? ?
          "https://steamcommunity.com/profiles/#{account_id}/inventory/" :
          "https://steamcommunity.com/id/#{account_name}/inventory/"

      option = {
          method: :post,
          url: url,
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'https://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => referer,
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          payload: {
              sessionid: sessionid,
              appid: 753,
              communityitemid: assetid,
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    rescue RestClient::Forbidden => e
      Authentication.refresh
      raise e
    end

    def load_booster_creators_by_third_party
      response = RestClient.get('http://steamtradingcards.wikia.com/wiki/Gems_by_Game')
      doc = Nokogiri::HTML(response.body)
    end

    def request_trade_offers(account, history)
      url = account.account_name.nil? ?
          "https://steamcommunity.com/profiles/#{account.account_id}/tradeoffers/" :
          "https://steamcommunity.com/id/#{account.account_name}/tradeoffers/"
      option = {
          method: :get,
          url: url,
          headers: {
              :params => {
                  history: history ? 1 : 0,
              },
              :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
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
      RestClient::Request.execute(option)
    end

    def load_trade_offers(account = Account::DEFAULT, history = false)
      response = request_trade_offers(account, history)
      doc = Nokogiri::HTML(response.body)
      trade_offers = doc.search('.tradeoffer').map do |trade_offer|
        id_match = trade_offer.attr('id').match(/tradeofferid_(\d+)/)
        id = id_match && id_match[1]
        report_attr = trade_offer.search('.btn_report').attr('href').value
        report_match = report_attr && report_attr.match(/javascript:ReportTradeScam\( '(\d+)', "([^"]+)" \);/)
        partner_id = report_match[1]
        partner_name = report_match[2]
        offer_item_list = trade_offer.search('.tradeoffer_item_list')
        their_offer_count = offer_item_list.first.search('.trade_item').size
        your_offer_count = offer_item_list.last.search('.trade_item').size
        status = TradeOffer.statuses[:pending]
        banner = trade_offer.search('.tradeoffer_items_banner').first
        status_desc = banner && banner.inner_text.strip
        if banner
          status_class = banner.attr('class').from(24)
          status = case status_class
            when 'accepted' then
              TradeOffer.statuses[:accepted]
            when 'in_escrow' then
              TradeOffer.statuses[:in_escrow]
            else
              TradeOffer.statuses[:declined]
          end
        end
        {
            account_id: account.id,
            trade_offer_id: id,
            partner_id: partner_id,
            partner_name: partner_name,
            your_offer_count: your_offer_count,
            their_offer_count: their_offer_count,
            status: status,
            status_desc: status_desc,
        }
      end
      TradeOffer.import(trade_offers, on_duplicate_key_update: {
          conflict_target: :trade_offer_id,
          columns: [:status, :status_desc],
      })
    end
  end
end
