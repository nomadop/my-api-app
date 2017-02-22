class AuthenticationsController < ApplicationController
  def show
    render json: AuthenticationRecord
  end

  def update
    AuthenticationRecord.update(params)
    render json: AuthenticationRecord
  end
end
