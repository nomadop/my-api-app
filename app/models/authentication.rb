class Authentication
  class << self
    attr_reader :redis

    def cookie
      redis.get(:cookie)
    end

    def cookie=(cookie)
      redis.set(:cookie, cookie)
    end

    def account
      redis.get(:account)
    end

    def account=(account)
      redis.set(:account, account)
    end

    def steam_id
      redis.get(:steam_id)
    end

    def steam_id=(steam_id)
      redis.set(:steam_id, steam_id)
    end

    def as_json(_)
      { cookie: cookie, account: account, steam_id: steam_id }
    end

    def update(params)
      self.steam_id = params[:steam_id] if params[:steam_id]
      self.account = params[:account] if params[:account]
      self.cookie = params[:cookie] if params[:cookie]
    end
  end

  @redis = Redis.new(db: 15)
end
