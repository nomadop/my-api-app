class BoosterCreator < ApplicationRecord
  before_save :set_trading_card_type
  after_create :create_or_scan_app

  has_one :steam_app, primary_key: :appid, foreign_key: :steam_appid
  has_one :booster_pack, -> { where(type: 'Booster Pack') },
          class_name: 'MarketAsset', primary_key: :appid, foreign_key: :market_fee_app
  has_many :trading_cards, -> { where('type like ?', '%Trading Card').where.not('type like ?', '%Foil Trading Card') },
           class_name: 'MarketAsset', primary_key: :appid, foreign_key: :market_fee_app
  has_many :foil_trading_cards, -> { where('type like ?', '%Foil Trading Card') },
           class_name: 'MarketAsset', primary_key: :appid, foreign_key: :market_fee_app
  has_many :trading_card_order_histograms, class_name: 'OrderHistogram',
           through: :trading_cards, source: :order_histogram
  has_many :foil_trading_card_order_histograms, class_name: 'OrderHistogram',
           through: :foil_trading_cards, source: :order_histogram
  has_many :listing_trading_cards, class_name: 'MyListing',
           through: :trading_cards, source: :my_listings
  has_many :listing_booster_packs, class_name: 'MyListing',
           through: :booster_pack, source: :my_listings
  has_many :account_booster_creators, primary_key: :appid, foreign_key: :appid
  has_many :accounts, through: :account_booster_creators
  has_many :inventory_assets, -> { where(account_id: 1) }, through: :booster_pack
  has_many :booster_creations

  scope :without_app, -> { left_outer_joins(:steam_app).where({steam_apps: {steam_appid: nil}}) }
  scope :no_trading_cards, -> { left_outer_joins(:trading_cards).where(market_assets: {type: nil}) }
  scope :unavailable, -> { where(unavailable: true) }
  scope :available, -> { where(unavailable: false) }
  scope :with_inventory_assets, -> { joins(:inventory_assets).distinct }

  scope :ppg_group, -> do
    join_sql = <<-SQL
      INNER JOIN "market_assets" 
      ON "market_assets"."market_fee_app" = "booster_creators"."appid"
      AND ("market_assets"."type" like '%Trading Card')
      AND (NOT("market_assets"."type" like '%Foil Trading Card'))
      INNER JOIN "order_histograms" 
      ON "order_histograms"."item_nameid" = "market_assets"."item_nameid"
      AND "order_histograms"."id" = (
        SELECT oh.id FROM order_histograms oh
        WHERE oh.item_nameid = market_assets.item_nameid
        ORDER BY oh.created_at DESC LIMIT 1
      )
    SQL
    joins(join_sql).group('booster_creators.id')
  end
  ppg_sql = '1.0 * SUM(order_histograms.lowest_sell_order) / COUNT(order_histograms.id) * 3 / price'
  scope :ppg_order, -> { ppg_group.order("#{ppg_sql} desc") }
  scope :ppg_having, ->(ppg) { ppg_group.having("(#{ppg_sql}) > #{ppg}") }

  delegate :lowest_sell_order, :highest_buy_order, :lowest_sell_order_exclude_vat, :highest_buy_order_exclude_vat,
           :sell_order_count, :buy_order_count, :order_count, :listing_url, to: :booster_pack, allow_nil: true

  class << self
    def refresh_price
      find_each(&:refresh_price_later)
    end

    def first_ppg_order(limit)
      ppg_order.first(limit)
    end

    def refresh_by_ppg_order(limit = 100)
      includes(trading_cards: :order_histogram, foil_trading_cards: :order_histogram, booster_pack: :order_histogram)
          .first_ppg_order(limit)
          .each(&:refresh_price_later)
    end

    def refresh_all
      includes(:trading_cards, :foil_trading_cards, :booster_pack)
          .each(&:refresh_price_later)
    end

    def scan_market
      find_each(&:scan_market)
    end

    def creatable(limit: 100, ppg: 0.6)
      includes(
          :accounts,
          :account_booster_creators,
          :trading_card_order_histograms,
          :foil_trading_card_order_histograms,
          :listing_trading_cards,
          :listing_booster_packs,
          booster_pack: :order_histogram,
      )
          .ppg_having(ppg)
    end

    def set_trading_card_type
      transaction do
        where(trading_card_type: nil).find_each do |booster_creator|
          booster_creator.set_trading_card_type
          booster_creator.save
        end
      end
    end
  end

  def trading_card_prices
    trading_card_order_histograms.pluck(:lowest_sell_order).compact
  end

  def foil_trading_card_prices
    foil_trading_card_order_histograms.pluck(:lowest_sell_order).compact
  end

  def trading_card_prices_exclude_vat
    trading_card_prices.map(&Utility.method(:exclude_val))
  end

  def foil_trading_card_prices_exclude_vat
    foil_trading_card_prices.map(&Utility.method(:exclude_val))
  end

  def trading_card_prices_proportion
    proportions = trading_card_order_histograms.map(&:proportion).compact
    return nil if proportions.blank?

    (proportions.sum / proportions.size).round(3)
  end

  def open_sell_order_count
    (1.0 * trading_card_order_histograms.map(&:sell_order_count).sum / trading_card_prices.count).round(3)
  end

  def open_buy_order_count
    (1.0 * trading_card_order_histograms.map(&:buy_order_count).sum / trading_card_prices.count).round(3)
  end

  def open_order_count
    1.0 * trading_card_order_histograms.map(&:order_count).sum / trading_card_prices.count
  end

  def open_price(include_vat = false)
    prices = include_vat ? trading_card_prices : trading_card_prices_exclude_vat
    foil_prices = include_vat ? foil_trading_card_prices : foil_trading_card_prices_exclude_vat
    average = 1.0 * prices.sum / prices.size
    foil_average = 1.0 * foil_prices.sum / foil_prices.size
    variance = prices.map { |price| (price - average) ** 2 }.sum / prices.size
    standard_variance = variance ** 0.5
    coefficient_of_variation = standard_variance / average
    baseline = self.price * 0.2
    prices_over_baseline = prices.select { |price| price >= baseline }
    prices_over_average = prices.select { |price| price >= average }
    {
        total: (average * 3).round(3),
        variance: variance.round(3),
        standard_variance: standard_variance.round(3),
        coefficient_of_variation: coefficient_of_variation.round(3),
        over_baseline_rate: (1.0 * prices_over_baseline.size / prices.size).round(3),
        over_average_rate: (1.0 * prices_over_average.size / prices.size).round(3),
        foil_average: foil_average.round(3),
    }
  end

  def open_price_per_goo(include_vat = false)
    prices = include_vat ? trading_card_prices : trading_card_prices_exclude_vat
    return 0 if prices.blank?

    (1.0 * prices.sum / prices.size * 3 / price).round(3)
  end

  def price_per_goo(include_vat = false)
    sell_price = include_vat ? lowest_sell_order : lowest_sell_order_exclude_vat
    return 0 if sell_price.nil?

    (1.0 * sell_price / price).round(3)
  end

  def createable?(ppg = 0.6)
    (booster_pack && price_per_goo > ppg) || open_price_per_goo > ppg
  end

  def listing_trading_card_count
    listing_trading_cards.size
  end

  def listing_booster_pack_count
    listing_booster_packs.size
  end

  def inventory_assets_count
    inventory_assets.count
  end

  def all_inventory_assets_count
    all_assets.count
  end

  def inventory_cards_count
    all_inventory_assets_count - inventory_assets_count
  end

  def sell_proportion
    booster_pack&.order_histogram&.proportion&.round(3)
  end

  def available_times
    account_booster_creators.map(&:available_time)
  end

  def min_available_time
    available_times.compact.min
  end

  def booster_pack_info
    return nil if trading_card_order_histograms.blank?
    as_json(
        only: [:appid, :name, :price],
        include: {
          account_booster_creators: {
            only: [],
            methods: [:bot_name, :available_time],
          },
        },
        methods: [
            :price_per_goo, :open_price_per_goo, :open_price, :trading_card_prices_proportion,
            :open_sell_order_count, :open_buy_order_count, :listing_trading_card_count, :listing_booster_pack_count,
            :lowest_sell_order, :sell_order_count, :buy_order_count, :sell_proportion, :listing_url,
            :min_available_time, :inventory_assets_count, :inventory_cards_count,
        ]
    )
  end

  def scan_market
    Market.scan(appid)
  end

  def refresh_price
    trading_card_order_histograms.each(&:refresh)
  end

  def refresh_price_later
    trading_cards.each(&:load_order_histogram)
    foil_trading_cards.each(&:load_order_histogram)
    booster_pack&.load_order_histogram
  end

  def set_trading_card_type
    self.trading_card_type = "#{name} Trading Card"
  end

  def create(account = Account::DEFAULT)
    response = Inventory.create_booster(appid, series, account)
    raise 'failed to create booster' unless response.code == 200
    result = JSON.parse(response.body)
    BoosterCreation.create(result['purchase_result'].merge(account: account, booster_creator: self))
    result['purchase_result']['communityitemid']
  end

  def create_all
    accounts.reload.each do |account|
      account_booster_creator = AccountBoosterCreator.find_by(appid: appid, account_id: account.id)
      next unless account_booster_creator&.available?
      create(account)
    end
  end

  def create_and_sell
    Market.load_order_histogram(booster_pack.item_nameid)
    accounts.reload.each do |account|
      account_booster_creator = AccountBoosterCreator.find_by(appid: appid, account_id: account.id)
      next unless account_booster_creator&.available?
      assetid = create(account)
      assetid && Inventory.sell(assetid, lowest_sell_order_exclude_vat - 1, 1, account)
    end
  end

  def create_and_unpack
    accounts.reload.each do |account|
      account_booster_creator = AccountBoosterCreator.find_by(appid: appid, account_id: account.id)
      next unless account_booster_creator&.available?
      assetid = create(account)
      assetid && Inventory.unpack_booster(assetid, account)
    end
  end

  def available_at
    DateTime.parse(available_at_time) unless available_at_time.blank?
  end

  def unpack_all
    inventory_assets.each(&:unpack_booster)
  end

  def sell_all
    inventory_assets.each(&:auto_sell_and_grind)
  end

  def all_assets(account = Account::DEFAULT)
    account
        .inventory_assets
        .includes(:market_asset)
        .where(market_assets: {market_fee_app: appid})
  end

  def sell_all_assets(account = Account::DEFAULT)
    all_assets(account).auto_sell_and_grind_later
  end

  def my_histories
    MyHistory.where('market_hash_name like ?', "#{appid}%")
  end

  def create_or_scan_app
    Steam.create_or_scan_app(appid)
  end

  def create_creation
    booster_creations.create(account: Account::DEFAULT, appid: appid)
  end

  def account_names
    accounts.map(&:bot_name)
  end

  def booster_creator_cost
    price
  end
end
