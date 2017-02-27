class Inventory
  class << self
    def load_all
      steam_id = Authentication.steam_id
      cookie = Authentication.cookie
      option = {
          method: :get,
          url: "http://steamcommunity.com/inventory/#{steam_id}/753/6?l=schinese",
          headers: {
              :Accept => '*/*',
              :'Accept-Encoding' => 'gzip, deflate, sdch',
              :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
              :'Cache-Control' => 'no-cache',
              :'Connection' => 'keep-alive',
              :'Cookie' => cookie,
              :'Host' => 'steamcommunity.com',
              :'Pragma' => 'no-cache',
              :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
          },
          proxy: 'http://127.0.0.1:8888'
      }
      response = RestClient::Request.execute(option)

      response.code == 200 ? JSON.parse(response.body) : {
          'assets' => [],
          'descriptions' => [],
      }
    end

    def load_all!
      result = load_all
      assets = result['assets']
      InventoryAsset.transaction do
        InventoryAsset.destroy_all
        InventoryAsset.create(assets)
      end
      descriptions = result['descriptions']
      InventoryDescription.transaction do
        descriptions.each do |json|
          description = InventoryDescription.find_or_create_by(
              classid: json['classid'],
              instanceid: json['instanceid']
          )
          description.update(json)
          description.load_market_asset if description.market_asset.nil?
        end
      end
    end

    def auto_sell
      inventory_assets = InventoryAsset.all
      order_histograms = inventory_assets.map(&:order_histogram).compact
      order_histograms.each(&:refresh)

      prepare = inventory_assets.select do |asset|
        price = asset.market_asset&.price_per_goo_exclude_vat || Float::INFINITY
        price&.> 0.6
      end
      prepare.each(&:quick_sell_later)
    end
  end
end