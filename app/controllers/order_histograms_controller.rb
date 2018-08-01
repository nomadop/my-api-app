class OrderHistogramsController < ApplicationController
  def list
    ids = JSON.parse(request.raw_post)
    result = OrderHistogram.where(item_nameid: ids)
    render json: result.as_json(except: [:id, :created_at, :updated_at])
  end
end
