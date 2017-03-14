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

      SteamApp.create(detail.slice('type', 'name', 'steam_appid', 'is_free', 'categories', 'genres'))
    end
  end
end