class AuthenticationsController < ApplicationController
  def initialize
    @redis = Redis.new
  end

  def show
    account = @redis.get(:account)
    cookie = @redis.get(:cookie)
    render json: { account: account, cookie: cookie }
  end

  def update
    account = params[:account]
    cookie = params[:cookie]
    @redis.set(:account, account)
    @redis.set(:cookie, cookie)
    render text: 'success!'
  end
end
