class Steam
  class << self
    attr_reader :default_account

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

    def load_friends(account = default_account)
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

    def add_friend(user, account = default_account)
      referer = user.account_id == user.steamid ?
          "http://steamcommunity.com/profiles/#{user.account_id}" :
          "http://steamcommunity.com/id/#{user.account_id}"
      option = {
          method: :post,
          url: 'http://steamcommunity.com/actions/AddFriendAjax',
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
  end

  @default_account = Account.find_by(account_id: '76561197967991989')
end