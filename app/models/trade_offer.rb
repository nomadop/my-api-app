class TradeOffer < ApplicationRecord
  belongs_to :account

  enum status: [:pending, :accepted, :declined]

  scope :gift_offer, -> { where(your_offer_count: 0) }
  scope :non_gift_offer, -> { where.not(your_offer_count: 0) }

  def gift_offer?
    your_offer_count == 0
  end

  def accept
    option = {
        method: :post,
        url: "https://steamcommunity.com/tradeoffer/#{trade_offer_id}/accept",
        headers: {
            :':authority' => 'steamcommunity.com',
            :':method' => 'POST',
            :':path' => "/tradeoffer/#{trade_offer_id}/accept",
            :':scheme' => 'https',
            :Accept => '*/*',
            :'Accept-Encoding' => 'gzip, deflate, br',
            :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
            :'Cache-Control' => 'no-cache',
            :'Connection' => 'keep-alive',
            :'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
            :'Cookie' => account.cookie,
            :'Origin' => 'https://steamcommunity.com',
            :'Pragma' => 'no-cache',
            :'Referer' => "https://steamcommunity.com/tradeoffer/#{trade_offer_id}/",
            :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36'
        },
        payload: {
            sessionid: account.session_id,
            serverid: 1,
            tradeofferid: trade_offer_id,
            partner: partner_id,
            captcha: '',
        },
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/certs/ca_certificate.pem',
    }
    response = RestClient::Request.execute(option)
    result = JSON.parse(response.body)
    accepted! if result['tradeid']
  end
end
