class AdminSessionsController < ApplicationController
  skip_before_action :require_login, except: [:destroy]

  def new
    @admin = Admin.new
  end

  def create
    if @admin = login(params[:email], params[:password], params[:remember])
      redirect_back_or_to(inventory_path, notice: 'Login successful')
    else
      flash.now[:alert] = 'Login failed'
      render action: 'new'
    end
  end

  def destroy
    logout
    redirect_to(login_path, notice: 'Logged out!')
  end
end
