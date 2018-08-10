class Steam
  class << self
    def request_app_list
      response = RestClient.get('http://api.steampowered.com/ISteamApps/GetAppList/v0002/')
      JSON.parse(response.body)
    end

    def request_app_detail(appid)
      response = SteamWeb.app_details(appid)
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
      SteamWeb.friends(account)
    end

    def load_friends(account = Account::DEFAULT)
      response = request_friends(account)
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
        ssl_ca_file: 'config/cert.pem',
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
      response = SteamWeb.search_community(query, page)
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
        { account_name: account_name, profile_url: profile_url, account_id: account_id, avatar_name: avatar_name, country: country }
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
      response = SteamWeb.set_nickname(user, nickname)
      JSON.parse(response.body)
    end

    def add_friend(user, account = Account::DEFAULT)
      response = SteamWeb.add_friend(user, account)
      JSON.parse(response.body)
    end

    def send_comment(user, comment)
      response = SteamWeb.comment(user ,comment)
      JSON.parse(response.body)
    end

    def request_account_history(account)
      response = SteamWeb.account_history(account)
      cursor = Utility.match_json_var('g_historyCursor', response.body)
      { cursor: cursor, html: response.body }
    end

    def request_more_account_history(account, cursor)
      response = SteamWeb.more_account_history(account, cursor)
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
        refunded = row.search('.wht_refunded').size > 0
        total_text = row.search('.wht_total').inner_text.gsub('资金', '').strip
        total_text_match = total_text.match(/¥\s+(?<price>\d+(\.\d+)?)/)
        total = total_text_match && total_text_match[:price].to_f * 100
        change_text = row.search('.wht_wallet_change').inner_text.strip
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
          refunded: refunded,
          total: total,
          change: change,
          balance: balance,
          total_text: total_text,
          change_text: change_text,
          balance_text: balance_text,
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
      Account.enabled.find_each { |account| LoadAccountHistoryJob.perform_later(account.id) }
    end

    def get_notification_counts(account = Account::DEFAULT)
      SteamWeb.get_notification_counts(account)
    end

    def request_game_page(account, appid)
      account.set_cookie(:mature_content, 1)
      response = SteamWeb.app(account, appid)
      account.update_cookie(response)
      response.body
    end

    def handle_game_page(body)
      doc = Nokogiri::HTML(body)
      purchase_area = doc.search('.game_area_purchase_game:not(.demo_above_purchase)').first
      price_text = purchase_area.search('.game_purchase_price').inner_text.strip
      subid_match = purchase_area.search('.btn_addtocart a').first&.attr('href')&.match(/^javascript:addToCart\((?<subid>\d+)\);$/)
      subid = subid_match&.[](:subid)
      snr = purchase_area.search('form input[name=snr]').first&.attr('value')
      { price_text: price_text, subid: subid, snr: snr }
    end

    def add_to_cart(account, appid, subid, snr)
      response = SteamWeb.cart(account, appid, subid, snr)
      account.update_cookie(response)
    end

    def init_transaction(account)
      response = SteamWeb.init_transaction(account)
      JSON.parse(response.body)
    end

    def get_final_price(account, transaction)
      response = SteamWeb.get_final_price(account, transaction)
      JSON.parse(response.body)
    end

    def finalize_transaction(account, transaction)
      response = SteamWeb.finalize_transaction(account, transaction)
      JSON.parse(response.body)
    end

    def buy_game(account, appid)
      account.remove_cookie(:shoppingCartGID)
      game_page = request_game_page(account, appid)
      game_info = handle_game_page(game_page)
      add_to_cart(account, appid, game_info[:subid], game_info[:snr])
      transaction = init_transaction(account)
      raise 'Failed to init transaction' unless transaction['success'] == 1
      final_price = get_final_price(account, transaction)
      raise 'Failed to get final price' unless final_price['success'] == 1
      result = finalize_transaction(account, transaction)
      raise 'Failed to finalize transaction' unless result['success'] == 22
      account.load_booster_creators
      result
    end

    def help_url(appid)
      "https://help.steampowered.com/zh-cn/wizard/HelpWithGame/?appid=#{appid}"
    end

    def request_help(account, appid)
      response = SteamWeb.help_with_game(account, appid)
      account.update_cookie(response)
      response.body
    end

    def handle_help_page(body)
      doc = Nokogiri::HTML(body)
      help_wizards = doc.search('.help_wizard_button.help_wizard_arrow_right')
      help_wizards.map do |wizard|
        link = wizard.attr('href')
        name = wizard.inner_text.strip
        { link: link, name: name }
      end
    end

    def submit_refund_request(account, url)
      response = SteamWeb.submit_refund_request(account, url)
      JSON.parse(response.body)
    end

    def refund_game(account, appid)
      raise 'no email address' if account.email_address.blank?
      account.remove_cookie(:steamHelpHistory)
      help_page = request_help(account, appid)
      help_wizards = handle_help_page(help_page)
      wizard = help_wizards.find { |wizard| wizard[:name] == '我不小心购买了此产品' }
      submit_refund_request(account, wizard[:link])
    end
  end
end
