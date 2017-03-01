class InventoryAsset < ApplicationRecord
  has_one :description,
          ->(asset) { where(instanceid: asset.instanceid) },
          class_name: 'InventoryDescription', primary_key: :classid, foreign_key: :classid

  has_one :market_asset, primary_key: :classid, foreign_key: :classid
  has_one :order_histogram, through: :market_asset

  def sell(price)
    account = Authentication.account
    cookie = Authentication.cookie
    scanner = HTTP::Cookie::Scanner.new(cookie)
    scanner.skip_until(/sessionid=/)
    sessionid = scanner.scan_value

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
            appid: appid,
            contextid: contextid,
            assetid: assetid,
            amount: amount,
            price: price,
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
    }
    RestClient::Request.execute(option)
  end

  def quick_sell
    sell(order_histogram.lowest_sell_order_exclude_vat)
  end

  def quick_sell_later
    return false if order_histogram.nil?

    queue = Sidekiq::Queue.new
    in_queue = queue.any? { |job| job.display_class == 'QuickSellAssetJob' && job.display_args == [id] }
    return false if in_queue

    QuickSellAssetJob.perform_later(id)
  end

  def grind_into_goo
    account = Authentication.account
    cookie = Authentication.cookie
    scanner = HTTP::Cookie::Scanner.new(cookie)
    scanner.skip_until(/sessionid=/)
    sessionid = scanner.scan_value

    option = {
        method: :post,
        url: "http://steamcommunity.com/id/#{account}/ajaxgrindintogoo/",
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
            :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
            :'X-Requested-With' => 'XMLHttpRequest',
        },
        payload: {
            sessionid: sessionid,
            appid: appid,
            contextid: contextid,
            assetid: assetid,
            goo_value_expected: market_asset.goo_value
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
    }
    RestClient::Request.execute(option)
  end
end
