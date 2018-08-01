class OrderHistogramsController < ApplicationController
  def list
    result = OrderHistogram.where(item_nameid: params[:ids].split(','))
    render json: result.as_json(except: [:id, :created_at, :updated_at])
  end
end
