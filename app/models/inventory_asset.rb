class InventoryAsset < ApplicationRecord
  has_one :description, class_name: 'InventoryDescription',
          primary_key: [:classid, :instanceid], foreign_key: [:classid, :instanceid]

  has_one :market_asset, primary_key: :classid, foreign_key: :classid
  has_one :order_histogram, through: :market_asset
  has_many :sell_histories, primary_key: :classid, foreign_key: :classid

  scope :marketable, -> { joins(:description).where(inventory_descriptions: {marketable: 1}) }
  scope :unmarketable, -> { joins(:description).where(inventory_descriptions: {marketable: 0}) }
  scope :without_market_asset, -> { left_outer_joins(:market_asset).where(market_assets: {classid: nil}) }
  scope :with_order_histogram, -> { joins(:order_histogram).distinct.includes(:order_histogram) }
  scope :without_order_histogram, -> { left_outer_joins(:order_histogram).where(order_histograms: {item_nameid: nil}) }

  delegate :marketable?, :market_hash_name, :load_market_asset, :marketable_date, to: :description
  delegate :price_per_goo, :price_per_goo_exclude_vat, :load_sell_histories_later, :find_sell_balance, :price_per_goo_exclude_vat, :goo_value, to: :market_asset, allow_nil: true
  delegate :lowest_sell_order, :sell_order_count, to: :order_histogram

  class << self
    def total_goo_value
      joins(:market_asset).sum(:goo_value)
    end
  end

  def refresh_price
    order_histogram.refresh
  end

  def sell(price)
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
            appid: appid,
            contextid: contextid,
            assetid: assetid,
            amount: amount,
            price: price,
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
    }
    response = RestClient::Request.execute(option)
    Authentication.update_cookie(response)
  end

  def quick_sell
    price = if sell_order_count && sell_order_count > 50 && market_asset&.sell_histories.with_in(1.week).exists?
              Utility.exclude_val(find_sell_balance(with_in: 1.week, balance: 0.8))
            else
              lowest = order_histogram.lowest_sell_order_exclude_vat
              lowest > 50 ? lowest - 1 : lowest
            end
    sell(price)
  end

  def quick_sell_later
    return false if order_histogram.nil?

    ApplicationJob.perform_unique(QuickSellAssetJob, id)
  end

  def grind_into_goo
    account = Authentication.account
    cookie = Authentication.cookie
    sessionid = Authentication.session_id

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
    response = RestClient::Request.execute(option)
    Authentication.update_cookie(response)
  end
end
