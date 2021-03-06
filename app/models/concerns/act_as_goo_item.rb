module ActAsGooItem
  extend ActiveSupport::Concern

  def get_goo_value(proxy = true)
    regexp = /GetGooValue\( '%contextid%', '%assetid%', *'?([0-9]+)'? *, *'?([0-9]+)'? *, *'?([0-9]+)'?/
    get_goo_action = owner_actions.find { |action| regexp.match?(action['link']) }
    return if get_goo_action.nil?

    _, appid, item_type, border_color = regexp.match(get_goo_action['link']).to_a

    option = {
        method: :get,
        url: 'https://steamcommunity.com/auction/ajaxgetgoovalueforitemtype/',
        headers: {
            :params => {
                appid: appid,
                item_type: item_type,
                border_color: border_color,
            },
            :Accept => '*/*',
            :'Accept-Encoding' => 'gzip, deflate, sdch',
            :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
            :'Cache-Control' => 'no-cache',
            :'Connection' => 'keep-alive',
            :'Host' => 'steamcommunity.com',
            :'Pragma' => 'no-cache',
            :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
        },
    }
    unless proxy
      option[:proxy] = 'http://localhost:8888'
      option[:ssl_ca_file] = 'config/cert.pem'
    end
    response = proxy ? TOR.request(option) : RestClient::Request.execute(option)

    result = JSON.parse(response.body)
    result['goo_value']
  end
end