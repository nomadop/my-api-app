class Account < ApplicationRecord
  DEFAULT = find(1)

  has_many :inventory_assets
  has_many :account_booster_creators
  has_many :booster_creators, through: :account_booster_creators
  has_many :my_histories
  has_many :trade_offers
  has_many :emails, primary_key: :email_address, foreign_key: :to
  has_many :account_histories
  has_many :my_listings

  enum status: [:enabled, :disabled, :expired]
  default_scope -> { enabled }

  class << self
    def load_booster_creators
      find_each(&:load_booster_creators)
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
      jar.add(cookie) unless cookie.name == name
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

  def send_items_to_default
    inventory_assets.non_gems.send_offer_to(Account::DEFAULT)
  end

  def accept_gift_offers
    trade_offers.gift_offer.pending.accept
  end

  def asf(command)
    raise 'no bot name' if bot_name.nil?
    ASF.send_command("#{command} #{bot_name}")
  end
end
