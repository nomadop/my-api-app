class MyListing < ApplicationRecord
  include ActAsListable
  self.inheritance_column = nil

  after_create :load_market_asset_later

  belongs_to :account
  has_one :market_asset, primary_key: :market_hash_name, foreign_key: :market_hash_name
  has_one :order_histogram, through: :market_asset
  has_one :steam_app, through: :market_asset
  has_one :booster_creator, through: :market_asset
  has_many :booster_creations, through: :booster_creator

  scope :belongs, ->(account) { where(account: account) }
  scope :booster_pack, -> { where('my_listings.market_hash_name like ?', '%Booster Pack') }
  scope :sack_of_gems, -> { where(market_hash_name: '753-Sack of Gems') }
  scope :non_sack_of_gems, -> { where.not(market_hash_name: '753-Sack of Gems') }
  scope :foil_card, -> { joins(:market_asset).where('market_assets.type like ?', '%Foil Trading Card') }
  scope :non_foil_card, -> { joins(:market_asset).where('market_assets.type like ?', '%Trading Card').where.not('market_assets.type like ?', '%Foil Trading Card') }
  scope :without_app, -> { left_outer_joins(:steam_app).where(steam_apps: { steam_appid: nil }) }
  scope :without_market_asset, -> { left_outer_joins(:market_asset).where(market_assets: { market_hash_name: nil }) }
  scope :without_order_histogram, -> { left_outer_joins(:order_histogram).where(order_histograms: { item_nameid: nil }) }
  scope :cancelable, -> do
    joins(:order_histogram).where <<-SQL
        my_listings.price > order_histograms.lowest_sell_order OR (
          my_listings.price > 100 AND 
          my_listings.price = order_histograms.lowest_sell_order AND 
          CAST(order_histograms.sell_order_graph->0->>1 AS int) - (
            SELECT COUNT(*) FROM "my_listings" AS "ml"
            WHERE "ml"."market_hash_name" = my_listings.market_hash_name
          ) > 3
        )
    SQL
  end
  scope :confirming, -> { where(confirming: true) }

  delegate :load_order_histogram, :find_sell_balance, :goo_value, :booster_pack?,
    :market_name, :market_fee_app, :type, to: :market_asset
  delegate :lowest_sell_order, :lowest_sell_order_exclude_vat, to: :order_histogram
  delegate :name, :booster_creator_cost, :booster_creations_count, to: :booster_creator, allow_nil: true
  delegate :bot_name, to: :account

  class << self
    def reload(start = 0, count = 100, account)
      result = Market.request_my_listings(start, count, account)
      return false unless result['success']

      Market.handle_my_listing_result(result, account)
      tail = start + count
      reload(tail, count, account) if tail < result['total_count']
    end

    def reload!(account = Account::DEFAULT)
      account = Account.enabled.find(account) unless account.is_a?(Account)
      transaction do
        belongs(account).delete_all
        reload(0, 100, account)
      end
    end

    def reload_all!(wait = true)
      Account.delegate_all([
        { class_name: :MyListing, method: :reload! },
        { class_name: :MyListing, method: :reload_confirming! },
      ], wait)
    end

    def reload_confirming(account = Account::DEFAULT)
      Market.load_confirming_listings(account)
    end

    def reload_confirming!(account = Account::DEFAULT)
      account = Account.enabled.find(account) unless account.is_a?(Account)
      where(account: account).confirming.delete_all
      reload_confirming(account)
    end

    def reload_all_confirming!
      Account.delegate_all({ class_name: :MyListing, method: :reload_confirming! })
    end

    def refresh_order_histogram(account)
      JobConcurrence.start do
        my_listings = account.nil? ? all : belongs(account)
        my_listings.includes(:market_asset).map { |market_asset| market_asset.load_order_histogram }
      end
    end

    def count_by_app
      joins(:steam_app).group('steam_apps.name').count
    end

    def cancel
      find_each(&:cancel)
    end

    def cancel_later
      all.map(&:cancel_later)
    end

    def cancel_cancelable(account = Account::DEFAULT)
      JobConcurrence.start do
        my_listings = account.nil? ? all : belongs(account)
        my_listings.non_sack_of_gems.cancelable
          .includes(:booster_creator, :market_asset, :order_histogram)
          .to_a.select(&:cancelable?)
          .map { |my_listing| my_listing.cancel_later }
      end
    end

    def cancel_dirty
      JobConcurrence.start { without_market_asset.cancel_later }
    end

    def reload_and_fresh(account = Account::DEFAULT)
      account.nil? ? Account.refresh_all : account.refresh
      account.nil? ? reload_all! : reload!(account)
      refresh_order_histogram(account)
    end

    def auto_resell(account = Account::DEFAULT)
      JobConcurrence.wait_for(cancel_dirty)
      JobConcurrence.wait_for(reload_and_fresh(account))
      JobConcurrence.wait_for(cancel_cancelable(account))
      JobConcurrence.wait_for(Inventory.auto_sell_and_grind(account))
      account.asf('2faok')
    end

    def auto_resell_all
      JobConcurrence.wait_for(cancel_dirty)
      JobConcurrence.wait_for(reload_and_fresh(nil))
      JobConcurrence.wait_for(cancel_cancelable(nil))
      JobConcurrence.wait_for(Inventory.auto_sell_and_grind(nil))
      Account.asf('2faok')
    end

    def auto_resell_all_by_step(step)
      case step
        when 1 then cancel_dirty
        when 2 then Account.refresh_all(false)
        when 3 then reload_all!(false)
        when 4 then refresh_order_histogram(nil)
        when 5 then cancel_cancelable(nil)
        when 6 then Inventory.reload_all!(false)
        when 7 then Inventory.auto_sell_and_grind(nil)
        when 8 then Account.asf('2faok')
        else return
      end
    end

    def cancel_pending_listings(account = Account::DEFAULT)
      doc = Nokogiri::HTML(Market.request_market(account))
      listing_sections = doc.search('.my_listing_section.market_content_block.market_home_listing_table')
      pending_section = listing_sections.find { |section| section.search('.my_market_header_active').inner_text == '我的等待确认的上架物品' }
      return if pending_section.nil?
      listing_rows = pending_section.search('.market_listing_row.market_recent_listing_row')
      return if listing_rows.blank?

      listing_rows.map do |row|
        listing_id = row.attr(:id).match(/\d+/)[0]
        ApplicationJob.perform_unique(CancelMyListingJob, listing_id)
      end
    end
  end

  def cancelable?
    if booster_creations_count&.>(0)
      price_of_base_ppg = booster_pack? ?
        (booster_creator.price * (booster_creator.base_ppg || 0.55)).ceil :
        (booster_creator.price * (booster_creator.base_ppg || 0.525) / 3).ceil
      return false unless order_histogram.lowest_sell_order_exclude_vat > price_of_base_ppg &&
        (price_exclude_vat - 1) > price_of_base_ppg
    end

    price > order_histogram.lowest_sell_order ||
      (price > 100 && price == order_histogram.lowest_sell_order && order_histogram.sell_order_graph[0][1] > 1)
  end

  def sell_balance(with_in: 1.week)
    market_asset.sell_balance(price, with_in: with_in)
  end

  def price_exclude_vat
    Utility.exclude_val(price)
  end

  def price_per_goo_exclude_vat
    return Float::INFINITY if price.nil? || goo_value.nil?

    1.0 * price_exclude_vat / goo_value
  end

  def cancel
    response = Market.cancel_my_listing(account, listingid)
    destroy if response.code == 200
  end

  def cancel_later
    ApplicationJob.perform_unique(CancelMyListingJob, listingid)
  end

  def market_asset_type
    market_asset.type
  end

  def load_market_asset_later
    ApplicationJob.perform_unique(LoadMarketAssetJob, nil, market_hash_name) if market_asset.nil?
  end

  def app_name
    steam_app&.name
  end
end
