class AuthenticationRecord
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

    def as_json(options)
      { cookie: cookie, account: account }
    end

    def update(params)
      self.account = params[:account]
      self.cookie = params[:cookie]
    end
  end

  @redis = Redis.new(db: 15)
end
