class Steam
  class << self
    def request_app_list
      response = RestClient.get('http://api.steampowered.com/ISteamApps/GetAppList/v0002/')
      JSON.parse(response.body)
    end

    def request_app_detail(appid)
      option = {
          method: :get,
          url: "http://store.steampowered.com/api/appdetails/?appids=#{appid}",
          proxy: 'http://127.0.0.1:3213',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)[appid.to_s]['data']
    end

    def load_app_list
      result = request_app_list
      apps = result['applist']['apps']
      appids = apps.map { |app| app['appid'] }
      exist_appids = SteamApp.pluck(:steam_appid)

      (appids - exist_appids).each { |appid| CreateSteamAppJob.perform_later(appid) }
    end

    def create_app(appid)
      detail = request_app_detail(appid)
      return if detail.nil?

      detail_slice = detail.slice('type', 'name', 'steam_appid', 'is_free', 'categories', 'genres')
      SteamApp.create(detail_slice) if SteamApp.where(steam_appid: detail['steam_appid']).empty?
    end

    def create_or_scan_app(appid)
      create_app(appid) || Market.scan(appid)
    end

    def request_friends(account)
      cookie = account.cookie
      account_name = account.account_name

      option = {
          method: :get,
          url: 'https://steamcommunity.com/actions/PlayerList/?type=friends',
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, sdch, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => "https://steamcommunity.com/id/#{account_name}/tradeoffers/sent/",
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    end

    def load_friends(account = Account::DEFAULT)
      response = request_friends(account)
      doc = Nokogiri::HTML(response)
      friends = doc.search('.friendBlock').map do |div|
        mini_profile = div.attr('data-miniprofile')
        profile_url = div.search('.friendBlockLinkOverlay').attr('href').value
        account_id = profile_url.split('/').last
        account_name = div.search('.friendBlockContent').children.first.inner_text.strip
        {profile: mini_profile, profile_url: profile_url, account_id: account_id, account_name: account_name}
      end
      Friend.import(friends, on_duplicate_key_update: {
          conflict_target: [:profile],
          columns: [:account_id, :account_name],
      })
    end

    def request_profile(url)
      option = {
          method: :get,
          url: url,
          headers: {
              :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              :'Accept-Encoding' => 'gzip, deflate, sdch, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Host' => 'steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    end

    def get_profile_data(url)
      html = request_profile(url)
      regexp = /g_rgProfileData = (.*);/i
      match = regexp.match(html)
      JSON.parse(match[1])
    end

    def search_user(query, page = 1)
      session_id = SecureRandom.hex(12)
      cookie = "sessionid=#{session_id}; steamCountry=SG%7C93545f6e98fa197ebd322680db9cae25; _ga=GA1.2.694042473.1497528360; _gid=GA1.2.1424724967.1497528360; timezoneOffset=28800,0"
      option = {
          method: :get,
          url: 'http://steamcommunity.com/search/SearchCommunityAjax',
          headers: {
              :params => {
                  text: query,
                  filter: :users,
                  sessionid: session_id,
                  steamid_user: false,
                  page: page,
              },
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, sdch',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => 'http://steamcommunity.com/search/users/',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          proxy: 'http://127.0.0.1:8888',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def handle_search_user_result(result)
      doc = Nokogiri::HTML(result['html'])
      rows = doc.search('.search_row')
      rows.map do |row|
        name_link = row.search('.searchPersonaInfo .searchPersonaName')
        account_name = name_link.inner_text
        profile_url = name_link.attr('href').value
        account_id = profile_url.split('/').last
        country_flag_img = row.search('.searchPersonaInfo img')
        country_match = country_flag_img.any? && country_flag_img.attr('src').value.match(/countryflags\/([^.]+)\.gif$/)
        country = country_match && country_match[1]
        avatar_medium_url = row.search('.avatarMedium img').attr('src').value
        avatar_name = avatar_medium_url.match(/\/([^\/.]+)_medium\.jpg/)[1]
        {account_name: account_name, profile_url: profile_url, account_id: account_id, avatar_name: avatar_name, country: country}
      end
    end

    def find_user(account_name, avatar_name)
      search_result = search_user(account_name)
      search_result_count = search_result['search_result_count']
      raise 'too many user found' if search_result_count > 300

      page = 1
      user = nil
      loop do
        users = handle_search_user_result(search_result)
        user = users.find { |user| user[:account_name] == account_name && avatar_name == user[:avatar_name] }

        break unless user.nil?
        search_result = search_user(account_name, page + 1) if page * 20 + 20 < search_result_count
      end

      user
    end

    def set_nickname(user, nickname)
      url = user.account_id == user.steamid ?
          "http://steamcommunity.com/profiles/#{user.account_id}/ajaxsetnickname/" :
          "http://steamcommunity.com/id/#{user.account_id}/ajaxsetnickname/"
      referer = user.account_id == user.steamid ?
          "http://steamcommunity.com/profiles/#{user.account_id}" :
          "http://steamcommunity.com/id/#{user.account_id}"
      option = {
          method: :post,
          url: url,
          headers: {
              :Accept => 'application/json, text/javascript, */*; q=0.01',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => Authentication.cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => referer,
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          payload: {
              nickname: nickname,
              sessionid: Authentication.session_id
          },
          proxy: 'http://127.0.0.1:8888',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def add_friend(user, account = Account::DEFAULT)
      referer = user.account_id == user.steamid ?
          "https://steamcommunity.com/profiles/#{user.account_id}" :
          "https://steamcommunity.com/id/#{user.account_id}"
      option = {
          method: :post,
          url: 'https://steamcommunity.com/actions/AddFriendAjax',
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => account.cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => referer,
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          payload: {
              steamid: user.steamid,
              sessionID: account.session_id,
              accept_invite: 0,
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def send_comment(user, comment)
      option = {
          method: :post,
          url: "http://steamcommunity.com/comment/Profile/post/#{user.steamid}/-1/",
          headers: {
              :Accept => 'text/javascript, text/html, application/xml, text/xml, */*',
              :'Accept-Encoding' => 'gzip, deflate',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
              :'Cookie' => Authentication.cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'Referer' => "http://steamcommunity.com/id/#{user.account_id}",
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Prototype-Version' => 1.7,
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          payload: {
              comment: comment,
              sessionid: Authentication.session_id,
              count: 6,
          },
          proxy: 'http://127.0.0.1:8888',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def request_account_history(account)
      option = {
          method: :get,
          url: 'https://store.steampowered.com/account/history/',
          headers: {
              :':authority' => 'store.steampowered.com',
              :':method' => 'GET',
              :':path' => '/account/history/',
              :':scheme' => 'https',
              :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
              :'Accept-Encoding' => 'gzip, deflate, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Cookie' => account.cookie,
              :'Pragma' => 'no-cache',
              :'upgrade-insecure-requests' => 1,
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      cursor = Utility.match_json_var('g_historyCursor', response.body)
      {cursor: cursor, html: response.body}
    end

    def request_more_account_history(account, cursor)
      param_str = <<~PATH
        cursor[wallet_txnid]=#{cursor['wallet_txnid']}&
        cursor[timestamp_newest]=#{cursor['timestamp_newest']}&
        cursor[balance]=#{cursor['balance']}&
        cursor[currency]=#{cursor['currency']}&
        sessionid=#{account.session_id}
      PATH
      param_str.gsub!(/\s/, '')
      option = {
          method: :get,
          url: "https://store.steampowered.com/account/AjaxLoadMoreHistory/?#{param_str}",
          headers: {
              :':authority' => 'store.steampowered.com',
              :':method' => 'GET',
              :':path' => "/account/history/?#{param_str}",
              :':scheme' => 'https',
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Cookie' => account.cookie,
              :'Pragma' => 'no-cache',
              :'Referer' => 'https://store.steampowered.com/account/history/',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body).symbolize_keys
    end

    def load_account_history(account = Account::DEFAULT, cursor = nil)
      result = cursor.nil? ? request_account_history(account) : request_more_account_history(account, cursor)
      doc = Nokogiri::HTML(result[:html])
      rows = doc.search('.wallet_table_row')
      account_histories = rows.map do |row|
        date_text = row.search('.wht_date').inner_text
        date = Time.strptime(date_text, '%Y年%m月%d日')
        items = row.search('.wht_items').children.map(&:inner_text).map(&:strip).reject(&:blank?)
        type = row.search('.wht_type div:first-child').inner_text.gsub(/[\t\r\n]/, '')
        payment = row.search('.wht_type .wth_payment').inner_text.gsub(/[\t\r\n]/, '')
        total_text = row.search('.wht_total').inner_text.strip
        total_text_match = total_text.match(/¥\s+(?<price>\d+(\.\d+)?)/)
        total = total_text_match && total_text_match[:price].to_f * 100
        change_text = row.search('.wht_wallet_change').inner_text
        change_text_match = change_text.match(/(?<type>[+-])¥\s+(?<price>\d+(\.\d+)?)/)
        change = change_text_match && change_text_match[:price].to_f * 100
        change = -change if change_text_match && change_text_match[:type] == '-'
        balance_text = row.search('.wht_wallet_balance').inner_text.strip
        balance_text_match = balance_text.match(/¥\s+(?<price>\d+(,\d+)*?(\.\d+)?)/)
        balance = balance_text_match && balance_text_match[:price].gsub(',', '').to_f * 100
        {
            account_id: account.id,
            date: date,
            items: items,
            type: type,
            payment: payment,
            total: total,
            change: change,
            balance: balance,
        }
      end
      AccountHistory.import(account_histories)
      result[:cursor]
    end

    def scan_account_history(account = Account::DEFAULT)
      AccountHistory.belongs(account).delete_all
      LoadAccountHistoryJob.perform_later(account.id)
    end

    def scan_all_account_history
      AccountHistory.truncate
      Account.find_each { |account| LoadAccountHistoryJob.perform_later(account.id) }
    end

    def get_notification_counts(account = Account::DEFAULT)
      option = {
          method: :get,
          url: 'https://steamcommunity.com/actions/GetNotificationCounts',
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, br',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Cookie' => account.cookie,
              :'Host' => 'steamcommunity.com',
              :'Origin' => 'http://store.steampowered.com',
              :'Pragma' => 'no-cache',
              :'Referer' => 'http://store.steampowered.com/',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    end
  end
end