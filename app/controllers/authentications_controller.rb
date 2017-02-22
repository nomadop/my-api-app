class AuthenticationsController < ApplicationController
  def show
    render json: Authentication
  end

  def update
    Authentication.update(params)
    render json: Authentication
  end
end
