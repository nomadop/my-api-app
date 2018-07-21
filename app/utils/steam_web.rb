class SteamWeb
  HELP_HOST = 'help.steampowered.com'
  STORE_HOST = 'store.steampowered.com'
  STORE_PATH = "https://#{STORE_HOST}"
  COMMUNITY_HOST = 'steamcommunity.com'
  COMMUNITY_PATH = "https://#{COMMUNITY_HOST}"

  class << self
    def app_details(appid)
      option = {
        method: :get,
        url: "#{STORE_PATH}/api/appdetails/?appids=#{appid}",
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/cert.pem',
      }
      RestClient::Request.execute(option)
    end

    def friends(account)
      cookie = account.cookie
      account_name = account.account_name

      option = get_option(
        :get, COMMUNITY_HOST, cookie,
        '/actions/PlayerList/?type=friends',
        "/id/#{account_name}/tradeoffers/sent/",
      )
      RestClient::Request.execute(option)
    end

    def search_community(query, page = 1)
      session_id = SecureRandom.hex(12)
      cookie = <<~COOKIE
        sessionid=#{session_id};
        steamCountry=SG%7C93545f6e98fa197ebd322680db9cae25;
        _ga=GA1.2.694042473.1497528360;
        _gid=GA1.2.1424724967.1497528360;
        timezoneOffset=28800,0
      COOKIE
      option = get_option(
        :get, COMMUNITY_HOST, cookie,
        '/search/SearchCommunityAjax',
        '/search/users/',
        headers: {
          params: {
            text: query,
            filter: :users,
            sessionid: session_id,
            steamid_user: false,
            page: page,
          },
        }
      )
      RestClient::Request.execute(option)
    end

    def set_nickname(user, nickname)
      option = get_option(
        :post, COMMUNITY_HOST,
        Authentication.cookie,
        get_user_path(user, '/ajaxsetnickname/'),
        get_user_path(user),
        payload: { nickname: nickname, sessionid: Authentication.session_id },
      )
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def add_friend(user, account = Account::DEFAULT)
      option = get_option(
        :post, COMMUNITY_HOST, account.cookie,
        '/actions/AddFriendAjax', get_user_path(user),
        payload: { steamid: user.steamid, sessionID: account.session_id, accept_invite: 0 },
      )
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def comment(user, comment)
      option = get_option(
        :post, COMMUNITY_HOST, Authentication.cookie,
        "/comment/Profile/post/#{user.steamid}/-1/",
        get_user_path(user),
        headers: { :'X-Prototype-Version' => 1.7 },
        payload: { comment: comment, sessionid: Authentication.session_id, count: 6 },
      )
      response = RestClient::Request.execute(option)
      JSON.parse(response.body)
    end

    def account_history(account)
      option = get_option(
        :get, STORE_HOST, account.cookie,
        '/account/history/',
        headers: {
          :':authority' => 'store.steampowered.com',
          :':method' => 'GET',
          :':path' => '/account/history/',
          :':scheme' => 'https',
          :Accept => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
          :'upgrade-insecure-requests' => 1,
        }
      )
      RestClient::Request.execute(option)
    end

    def more_account_history(account, cursor)
      param_str = <<~PATH
        cursor[wallet_txnid]=#{cursor['wallet_txnid']}&
        cursor[timestamp_newest]=#{cursor['timestamp_newest']}&
        cursor[balance]=#{cursor['balance']}&
        cursor[currency]=#{cursor['currency']}&
        sessionid=#{account.session_id}
      PATH
      param_str.gsub!(/\s/, '')
      option = get_option(
        :get, STORE_HOST, account.cookie,
        "/account/AjaxLoadMoreHistory/?#{param_str}",
        '/account/history/',
        headers: {
          :':authority' => 'store.steampowered.com',
          :':method' => 'GET',
          :':path' => "/account/history/?#{param_str}",
          :':scheme' => 'https',
        }
      )
      RestClient::Request.execute(option)
    end

    def get_notification_counts(account)
      option = get_option(
        :get, COMMUNITY_HOST, account.cookie,
        '/actions/GetNotificationCounts', '/',
      )
      RestClient::Request.execute(option)
    end

    def app(account, appid)
      option = get_option(
        :get, STORE_HOST, account.cookie, "/app/#{appid}",
        headers: { :'upgrade-insecure-requests' => 1 },
      )
      RestClient::Request.execute(option)
    end

    def cart(account, appid, subid, snr)
      option = get_option(
        :post, STORE_HOST, account.cookie, '/cart/', "/app/#{appid}/",
        headers: { :'Upgrade-Insecure-Requests' => 1 },
        payload: { snr: snr, action: :add_to_cart, sessionid: account.session_id, subid: subid },
      )
      RestClient::Request.execute(option)
    end

    def init_transaction(account)
      option = get_option(
        :post, STORE_HOST, account.cookie,
        '/checkout/inittransaction/', '/checkout/?purchasetype=self',
        headers: { :'X-Prototype-Version' => 1.7 },
        payload: {
          gidShoppingCart: account.get_cookie(:shoppingCartGID),
          gidReplayOfTransID: -1,
          PaymentMethod: :steamaccount,
          abortPendingTransactions: 0,
          bHasCardInfo: 0,
          Country: :CN,
          ShippingCountry: :CN,
          bIsGift: 0,
          GifteeAccountID: 0,
          ScheduledSendOnDate: 0,
          bSaveBillingAddress: 1,
          bUseRemainingSteamAccount: 1,
          bPreAuthOnly: 0,
          sessionid: account.session_id,
        },
      )
      RestClient::Request.execute(option)
    end

    def get_final_price(account, transaction)
      option = get_option(
        :get, STORE_HOST, account.cookie,
        '/checkout/getfinalprice/', '/checkout/?purchasetype=self',
        headers: {
          :'X-Prototype-Version' => 1.7,
          :params => {
            count: 1,
            transid: transaction['transid'],
            purchasetype: :self,
            microtxnid: -1,
            cart: account.get_cookie(:shoppingCartGID),
            gidReplayOfTransID: -1,
          },
        },
      )
      RestClient::Request.execute(option)
    end

    def finalize_transaction(account, transaction)
      option = get_option(
        :post, STORE_HOST, account.cookie,
        '/checkout/finalizetransaction/', '/checkout/?purchasetype=self',
        headers: { :'X-Prototype-Version' => 1.7 },
        payload: { transid: transaction['transid'] },
      )
      RestClient::Request.execute(option)
    end

    def help_with_game(account, appid)
      option = get_option(
        :get, HELP_HOST, account.cookie, get_help_path(appid),
        headers: { :'upgrade-insecure-requests' => 1 },
      )
      RestClient::Request.execute(option)
    end

    def submit_refund_request(account, url)
      uri = URI.parse(url)
      query_set = uri.query.split('&').map{ |param| param.split('=') }
      query = Hash[query_set]
      option = get_option(
        :post, HELP_HOST, account.cookie,
        '/zh-cn/wizard/AjaxSubmitRefundRequest/', url,
        payload: {
          sessionid: account.session_id,
          wizard_ajax: 1,
          help_issue_origin: query['issueid'],
          help_issue: query['issueid'],
          contact_email: account.email_address,
          issue_appid: query['appid'],
          issue_transid: query['transid'],
          issue_line_item: query['line_item'],
          refund_to_wallet: 1,
        },
      )
      RestClient::Request.execute(option)
    end

    private
    def get_help_path(appid)
      "/zh-cn/wizard/HelpWithGame/?appid=#{appid}"
    end

    def get_user_path(user, path = '')
      user.account_id == user.steamid ? "/profiles/#{user.account_id}#{path}" : "/id/#{user.account_id}#{path}"
    end

    def get_option(method, host, cookie, path, referer_path = nil, **option)
      url = "https://#{host}#{path}"
      headers = {
        :Accept => '*/*',
        :'Accept-Encoding' => 'gzip, deflate, sdch, br',
        :'Accept-Language' => 'zh-CN,zh;q=0.8,en;q=0.6,ja;q=0.4,zh-TW;q=0.2',
        :'Cache-Control' => 'no-cache',
        :'Connection' => 'keep-alive',
        :'Cookie' => cookie,
        :'Host' => host,
        :'Pragma' => 'no-cache',
        :'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36',
        :'X-Requested-With' => 'XMLHttpRequest',
      }
      if method == :post
        headers[:Origin] = "https://#{host}"
        headers[:'Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
      end
      headers[:Referer] = "https://#{host}#{referer_path}" unless referer_path.nil?

      options = {
        method: method,
        url: url,
        headers: headers,
        proxy: 'http://127.0.0.1:8888',
        ssl_ca_file: 'config/cert.pem',
      }
      options.deep_merge(option)
    end
  end
end