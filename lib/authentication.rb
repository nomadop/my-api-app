require 'execjs'

class Authentication
  class << self
    attr_reader :default_account
    delegate :account_name, :account_id, :cookie, :session_id, :refresh, to: :default_account

    alias_method :account, :account_name
    alias_method :steam_id, :account_id

    def check_login(cookie)
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
      RestClient::Request.execute(option)
    end

    def get_rsa_key(username)
      option = {
          method: :post,
          url: 'https://store.steampowered.com/login/getrsakey',
          headers: {
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          payload: {
              username: username,
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def do_login(username, password, rsa_timestamp, two_factory_code = '')
      option = {
          method: :post,
          url: 'https://store.steampowered.com/login/dologin',
          headers: {
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          payload: {
              username: username,
              password: password,
              emailauth: '',
              twofactorcode: two_factory_code,
              loginfriendlyname: '',
              captchagid: -1,
              captcha_text: '',
              emailsteamid: '',
              remember_login: true,
              rsatimestamp: rsa_timestamp,
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def login(username, password)
      rsa_key = get_rsa_key(username)
      password.gsub!(/[^\x00-\x7F]/, '')

      rsa_js_source = File.read('lib/rsa.js')
      js_context = ExecJS.compile(rsa_js_source)
      encrypted_password = js_context.eval <<-JAVASCRIPT
        RSA.encrypt(
          '#{password}', 
          RSA.getPublicKey('#{rsa_key['publickey_mod']}', '#{rsa_key['publickey_exp']}')
        )
      JAVASCRIPT

      rsa_timestamp = rsa_key['timestamp']
      do_login(username, encrypted_password, rsa_timestamp)
      puts 'input two factory code:'
      two_factory_code = gets.chomp
      do_login(username, encrypted_password, rsa_timestamp, two_factory_code)
    end
  end

  @default_account = Account.take.reload
end
