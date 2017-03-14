class Steam
  class << self
    def request_app_detail(appid)
      response = RestClient.get('http://store.steampowered.com/api/appdetails/', {
          params: { appids: appid }
      })
      JSON.parse(response.body)[appid.to_s]['data']
    end

    def create_app(appid)
      detail = request_app_detail(appid)
      return if detail.nil?

      detail_slice = detail.slice('type', 'name', 'steam_appid', 'is_free', 'categories', 'genres')
      SteamApp.create(detail_slice) if SteamApp.where(steam_appid: detail['steam_appid']).empty?
    end
  end
end