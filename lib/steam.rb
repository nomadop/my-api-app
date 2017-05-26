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

    def request_friends
      cookie = Authentication.cookie
      account = Authentication.account

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
              :'Referer' => "https://steamcommunity.com/id/#{account}/tradeoffers/sent/",
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
              :'X-Requested-With' => 'XMLHttpRequest',
          },
          proxy: 'http://127.0.0.1:8888',
          ssl_ca_file: 'config/certs/ca_certificate.pem',
      }
      RestClient::Request.execute(option)
    end

    def load_friends
      response = request_friends
      doc = Nokogiri::HTML(response)
      friends = doc.search('.friendBlock').map do |div|
        mini_profile = div.attr('data-miniprofile')
        profile_url = div.search('.friendBlockLinkOverlay').attr('href').value
        account_id = profile_url.split('/').last
        account_name = div.search('.friendBlockContent').children.first.inner_text.strip
        { profile: mini_profile, profile_url: profile_url, account_id: account_id, account_name: account_name }
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
  end
end