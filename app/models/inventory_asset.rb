class InventoryAsset < ApplicationRecord
  GEMS_CLASSID = 667924416
  SACK_OF_GEMS_CLASSID = 667933237
  self.inheritance_column = nil

  belongs_to :account
  has_one :description, class_name: 'InventoryDescription',
          primary_key: [:classid, :instanceid], foreign_key: [:classid, :instanceid]

  has_one :market_asset, primary_key: :classid, foreign_key: :classid
  has_many :my_listings, through: :market_asset
  has_one :booster_creator, through: :market_asset
  has_many :booster_creations, through: :booster_creator
  has_one :order_histogram, through: :market_asset
  has_one :steam_app, through: :market_asset
  has_many :sell_histories, primary_key: :classid, foreign_key: :classid

  scope :belongs, ->(account) { where(account: account) }
  scope :booster_pack, -> { joins(:market_asset).where(market_assets: {type: 'Booster Pack'}) }
  scope :non_booster_pack, -> { joins(:market_asset).where.not(market_assets: {type: 'Booster Pack'}) }
  scope :marketable, -> { joins(:description).where(inventory_descriptions: {marketable: 1}) }
  scope :unmarketable, -> { joins(:description).where(inventory_descriptions: {marketable: 0}) }
  scope :tradable, -> { joins(:description).where(inventory_descriptions: {tradable: 1}) }
  scope :untradable, -> { joins(:description).where(inventory_descriptions: {tradable: 0}) }
  scope :gems, -> { where(classid: GEMS_CLASSID) }
  scope :non_gems, -> { where.not(classid: GEMS_CLASSID) }
  scope :sacks_of_gem, -> { where(classid: SACK_OF_GEMS_CLASSID) }
  scope :non_sacks_of_gem, -> { where.not(classid: SACK_OF_GEMS_CLASSID) }
  scope :without_market_asset, -> { left_outer_joins(:market_asset).where(market_assets: {classid: nil}) }
  scope :with_order_histogram, -> { joins(:order_histogram).distinct.includes(:order_histogram) }
  scope :without_order_histogram, -> { left_outer_joins(:order_histogram).where(order_histograms: {item_nameid: nil}) }

  delegate :marketable, :marketable?, :unmarketable?, :marketable_date,
           :load_market_asset, :owner_descriptions, to: :description
  delegate :price_per_goo, :price_per_goo_exclude_vat, :load_sell_histories_later, :find_sell_balance,
           :open_price_per_goo, :load_order_histogram, :listing_url, :type, :market_hash_name,
           :goo_value, :booster_pack?, :refresh_goo_value, :booster_pack_info, :market_fee_app,
           to: :market_asset, allow_nil: true
  delegate :lowest_sell_order, :sell_order_count, :highest_buy_order, :buy_order_count,
           :lowest_sell_order_exclude_vat, :highest_buy_order_exclude_vat,
           to: :order_histogram, allow_nil: true
  delegate :booster_creations_count, to: :booster_creator, allow_nil: true
  delegate :bot_name, to: :account

  class << self
    def total_goo_value
      joins(:market_asset).sum(:goo_value)
    end

    def tradable_gems(account = Account::DEFAULT)
      belongs(account).gems.tradable.order('cast(amount as int) desc')
    end

    def auto_sell_and_grind_later
      all.map(&:auto_sell_and_grind_later).compact
    end

    def find_biggest_tradable_gem
      gems.tradable.order('amount::int').last
    end

    def names
      joins(:market_asset).pluck('market_assets.market_hash_name')
    end

    def count_by_app
      joins(:steam_app).group('steam_apps.name').count
    end

    def generate_trade_offer
      assets = find_each.map do |asset|
        {appid: 753, contextid: 6, amount: asset.amount, assetid: asset.assetid}
      end
      offer = {
          newversion: true,
          version: 2,
          me: {
              assets: assets,
              currency: [],
              ready: false,
          },
          them: {assets: [], currency: [], ready: false},
      }
      offer.to_json
    end

    def send_offer_to(friend)
      friend = Friend.find_by(steamid: friend.account_id) if friend.is_a?(Account)
      accounts = find_each.map(&:account).uniq
      raise 'assets from different accounts' if accounts.size > 1
      Market.send_trade(accounts.first, friend.profile, friend.steamid, generate_trade_offer)
      destroy_all
    end

    def load_missing_market_assets
      without_market_asset.find_each(&:load_market_asset)
    end
  end

  def refresh_price
    order_histogram.refresh
  end

  def sell(price, amount = self.amount.to_i)
    response = Inventory.sell(assetid, price, amount, account)
    result = JSON.parse(response.body)
    if result['success']
      remain_amount = self.amount.to_i - amount
      remain_amount > 0 ? update(amount: remain_amount) : destroy
    else
      puts result['message']
    end
    result
  end

  def sell_by_ppg(ppg)
    sell((goo_value * ppg).ceil)
  end

  def quick_sell
    price = begin
      lowest = order_histogram.lowest_sell_order_exclude_vat
      raise 'failed to quick sell cause of no lowest price' if lowest.nil?
      equals_listing = my_listings.exists? && my_listings.take.price_exclude_vat == lowest
      lowest <= 50 || equals_listing ? lowest : lowest - 1
    end
    if booster_creations.exists?
      price = booster_pack? ?
        [price, (booster_creator.price * (booster_creator.base_ppg || 0.55)).ceil].max :
        [price, (booster_creator.price * (booster_creator.base_ppg || 0.525) / 3).ceil].max
    end
    puts "#{Time.now}: quick sell #{account.bot_name}'s `#{market_hash_name}(#{type})' for #{Utility.format_price(price)}."
    sell(price)
  end

  def quick_sell_later
    return false if order_histogram.nil?

    ApplicationJob.perform_unique(QuickSellAssetJob, id)
  end

  def grind_into_goo
    profile_url = account.account_name.blank? ?
      "https://steamcommunity.com/profiles/#{account.account_id}" :
      "https://steamcommunity.com/id/#{account.account_name}"
    cookie = account.cookie
    sessionid = account.session_id

    option = {
        method: :post,
        url: "#{profile_url}/ajaxgrindintogoo/",
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
            :'Referer' => "#{profile_url}/inventory/",
            :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
            :'X-Requested-With' => 'XMLHttpRequest',
        },
        payload: {
            sessionid: sessionid,
            appid: market_fee_app,
            contextid: contextid,
            assetid: assetid,
            goo_value_expected: market_asset.goo_value
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/cert.pem',
    }
    response = RestClient::Request.execute(option)
    puts "#{Time.now}: grind #{account.bot_name}'s `#{market_hash_name}(#{type})' into goo for #{market_asset.goo_value}."
    account.update_cookie(response)
    result = JSON.parse(response.body)
    destroy if result['success'] == 1
    result
  rescue RestClient::Forbidden => e
    account.refresh
    raise e
  end

  def exchange_goo(amount)
    account_name = account.account_name
    cookie = account.cookie
    sessionid = account.session_id

    payload = if classid == GEMS_CLASSID
      {
          sessionid: sessionid,
          appid: appid,
          assetid: assetid,
          goo_denomination_in: 1,
          goo_amount_in: amount * 1000,
          goo_denomination_out: 1000,
          goo_amount_out_expected: amount,
      }
    else
      {
          sessionid: sessionid,
          appid: appid,
          assetid: assetid,
          goo_denomination_in: 1000,
          goo_amount_in: amount,
          goo_denomination_out: 1,
          goo_amount_out_expected: amount * 1000,
      }
    end

    option = {
        method: :post,
        url: "https://steamcommunity.com/id/#{account_name}/ajaxexchangegoo/",
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
            :'Referer' => "http://steamcommunity.com/id/#{account_name}/inventory/",
            :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
            :'X-Requested-With' => 'XMLHttpRequest',
        },
        payload: payload,
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/cert.pem',
    }
    response = RestClient::Request.execute(option)
    if JSON.parse(response.body)['success'] == 1
      cost = classid == GEMS_CLASSID ? amount * 1000 : amount
      remain_amount = self.amount.to_i - cost
      remain_amount > 0 ? update(amount: remain_amount) : destroy
    end
  rescue RestClient::Forbidden => e
    account.refresh
    raise e
  end

  def unpack_booster
    response = Inventory.unpack_booster(assetid, account)
    destroy if JSON.parse(response.body)['success'] == 1
  end

  def auto_sell_and_grind
    if marketable? || order_histogram.nil? || order_histogram.updated_at < 3.hours.ago
      Market.load_order_histogram(market_asset.item_nameid, false)
      market_asset.refresh_goo_value(false)
    end
    ppg = reload.price_per_goo_exclude_vat
    raise "invalid price per goo for `#{market_hash_name}'" if ppg.nil?
    return quick_sell if marketable? && (ppg > 1 || (booster_pack? && booster_creations.exists?))
    grind_into_goo if ppg <= 2 && !booster_pack? && !booster_creations.exists?
  end

  def auto_sell_and_grind_later
    return if market_asset.nil?
    ApplicationJob.perform_unique(AutoSellAndGrindJob, id)
  end

  def generate_trade_offer(amount)
    offer = {
        newversion: true,
        version: 2,
        me: {
            assets: [{appid: 753, contextid: 6, amount: amount, assetid: assetid}],
            currency: [],
            ready: false,
        },
        them: {assets: [], currency: [], ready: false},
    }
    offer.to_json
  end

  def send_offer_to(friend, amount = 1)
    friend = Friend.find_by(steamid: friend.account_id) if friend.is_a?(Account)
    friend = Friend.find_by(account_name: friend) if friend.is_a?(String)
    Market.send_trade(account, friend.profile, friend.steamid, generate_trade_offer(amount))
    remaining_amount = self.amount.to_i - amount
    remaining_amount > 0 ? update(amount: remaining_amount) : destroy
  end
end
