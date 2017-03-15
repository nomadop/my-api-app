class Steam
  class << self
    def request_app_list
      response = RestClient.get('http://api.steampowered.com/ISteamApps/GetAppList/v0002/')
      JSON.parse(response.body)
    end

    def request_app_detail(appid)
      response = RestClient.get('http://store.steampowered.com/api/appdetails/', {
          params: {appids: appid}
      })
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
  end
end