class Authentication
  ALLOWED_COOKIES = %w(Steam_Language browserid lastagecheckage sessionid steamCountry steamLogin steamLoginSecure steamRememberLogin webTradeEligibility timezoneOffset)

  class << self
    attr_reader :redis

    def cookie
      redis.get(:cookie)
    end

    def cookie=(cookie)
      redis.set(:cookie, cookie)
    end

    def account
      redis.get(:account)
    end

    def account=(account)
      redis.set(:account, account)
    end

    def steam_id
      redis.get(:steam_id)
    end

    def steam_id=(steam_id)
      redis.set(:steam_id, steam_id)
    end

    def as_json(_)
      { cookie: cookie, account: account, steam_id: steam_id }
    end

    def update(params)
      self.steam_id = params[:steam_id] if params[:steam_id]
      self.account = params[:account] if params[:account]
      self.cookie = params[:cookie] if params[:cookie]
    end

    def cookie_jar
      uri = URI('http://store.steampowered.com')
      parse_cookie = Proc.new {|c| HTTP::Cookie.parse(c, uri)}
      cookie
          .split(';')
          .flat_map(&parse_cookie)
          .select { |cookie| cookie.name.in?(ALLOWED_COOKIES) }
          .reduce(HTTP::CookieJar.new, &:add)
    end

    def get_cookie(name)
      cookie = cookie_jar.find { |cookie| cookie.name == name.to_s }
      cookie.value
    end

    def set_cookie(name, value)
      jar = cookie_jar.tap do |jar|
        cookie = jar.parse("#{name}=#{value}", URI('http://store.steampowered.com'))[0]
        jar.add(cookie) if cookie.name.in?(ALLOWED_COOKIES)
      end
      self.cookie = jar.cookies.join(';')
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
        jar.add(cookie) if cookie.name.in?(ALLOWED_COOKIES)
        jar
      end
      self.cookie = jar.cookies.join(';')
    end

    def refresh
      option = {
          method: :get,
          url: 'https://store.steampowered.com/login/checkstoredlogin/?redirectURL=0',
          headers: {
              :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              :'Accept-Encoding' => 'gzip, deflate, sdch, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => cookie,
              :'Host' => 'store.steampowered.com',
              :'Pragma' => 'no-cache',
              :'Upgrade-Insecure-Requests' => 1,
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      update_cookie(response)
    end
  end

  @redis = Redis.new(db: 15)
end
