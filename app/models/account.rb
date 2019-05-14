class Account < ApplicationRecord
  DEFAULT = Account.first

  has_many :inventory_assets
  has_many :account_booster_creators
  has_many :booster_creators, through: :account_booster_creators
  has_many :my_histories
  has_many :trade_offers
  has_many :emails, primary_key: :email_address, foreign_key: :to
  has_many :account_histories
  has_many :my_listings
  has_many :buy_orders
  has_many :owned_market_assets, class_name: 'MarketAsset', foreign_key: :order_owner_id
  has_one :steam_user, primary_key: :account_id, foreign_key: :steamid
  scope :has_bot, -> { where.not(bot_name: nil) }

  enum status: [:enabled, :disabled, :expired]

  class << self
    def delegate_all(class_methods, wait = true)
      class_methods = [class_methods] unless class_methods.is_a?(Array)
      proc = Proc.new do
        class_methods.flat_map do |class_method|
          enabled.map { |account| DelegateJob.perform_later(class_method[:class_name].to_s, class_method[:method].to_s, account.id) }
        end
      end
      wait ? JobConcurrence.start_and_wait_for(&proc) : JobConcurrence.start(&proc)
    end

    def load_booster_creators(account_id)
      find(account_id).load_booster_creators
    end

    def load_all_booster_creators
      delegate_all({class_name: :Account, method: :load_booster_creators})
    end

    def asf(command)
      JobConcurrence.start do
        enabled.has_bot.find_each.map do |account|
          DelegateJob.perform_later('ASF', 'send_command', "#{command} #{account.bot_name}")
        end
      end
    end

    def refresh(id_or_name)
      account = id_or_name.is_a?(Integer) ? find(id_or_name) : find_by(bot_name: id_or_name)
      account.refresh
    end

    def refresh_all(wait = true)
      delegate_all({class_name: :Account, method: :refresh}, wait)
    end

    def method_missing(method, *args, &block)
      find_by(bot_name: method) || super(method, *args, &block)
    end

    def search(id_or_bot_name)
      id_or_bot_name.is_a?(Integer) ? super(id_or_bot_name) : find_by(bot_name: id_or_bot_name)
    end

    def balances
      balances = enabled.map {|account| [account.bot_name, Utility.format_price(account.balance)]}
      Hash[balances.sort]
    end
  end

  def cookie
    reload
    super
  end

  def cookie_jar
    return HTTP::CookieJar.new if cookie.nil?

    Utility.parse_cookies(cookie.split(';')).reduce(HTTP::CookieJar.new, &:add)
  end

  def get_cookie(name)
    cookie = cookie_jar.find { |cookie| cookie.name == name.to_s }
    cookie.value
  end

  def set_cookie(name, value)
    jar = cookie_jar.tap do |jar|
      cookie = jar.parse("#{name}=#{value}", URI('http://store.steampowered.com'))[0]
      jar.add(cookie)
    end
    update(cookie: jar.cookies.join(';'))
  end

  def remove_cookie(name)
    jar = Utility.parse_cookies(cookie.split(';')).reduce(HTTP::CookieJar.new) do |jar, cookie|
      jar.add(cookie) unless cookie.name == name.to_s
      jar
    end
    update(cookie: jar.cookies.join(';'))
  end

  def session_id
    get_cookie(:sessionid)
  end

  def session_id=(session_id)
    set_cookie(:sessionid, session_id)
  end

  def update_cookie(response)
    jar = response.cookie_jar.cookies.reduce(cookie_jar) do |jar, cookie|
      cookie = jar.parse(cookie.to_s, URI('http://store.steampowered.com'))[0]
      jar.add(cookie) unless cookie.name == 'steamRememberLoginError'
      jar
    end
    update(cookie: jar.cookies.join(';'))
  end

  def refresh
    response = Authentication.check_login(cookie)
    update_cookie(response)
  rescue Authentication::AccountExpired => e
    expired!
    raise(e)
  end

  def reload_inventory
    Inventory.reload!(self)
  end

  def load_booster_creators
    Inventory.load_booster_creators(self)
  end

  def gem_amount_info
    Inventory.gem_amount_info(self)
  end

  def load_friends
    Steam.load_friends(self)
  end

  def create_steam_user(name)
    SteamUser.create(account_name: name, account_id: account_id, steamid: account_id)
  end

  def load_trade_offers(history = false)
    Inventory.load_trade_offers(self, history)
  end

  def eligibility_check
    Market.eligibility_check(self)
  end

  def eligibility
    cookie = get_cookie('webTradeEligibility')
    JSON.parse(URI.decode(cookie))
  end

  def pull_notification_counts
    GetNotificationCountsJob.perform_later(id)
  end

  def send_items(target = Account::DEFAULT)
    return if id == target.id
    inventory_assets.non_gems.tradable.send_offer_to(target)
  end

  def send_items_later(target = Account::DEFAULT)
    ApplicationJob.perform_unique(SendItemsJob, id, target.id)
  end

  def accept_gift_offers
    trade_offers.gift_offer.pending.accept
  end

  def asf(command)
    raise 'no bot name' if bot_name.nil?
    ASF.send_command("#{command} #{bot_name}")
  end

  def fa_code
    raise 'no bot name' if bot_name.nil?
    result = asf('2fa')['Result']
    match = result.match(/2FA Token: (.{5})$/)
    match.nil? ? raise('2fa failed') : match[1]
  end

  def balance
    account_histories.market.first.balance +
      account_histories.purchase.not_refunded.with_in(2.week).sum(:total) +
      account_histories.unconfirmed.refund.sum(:total)
  end
end
