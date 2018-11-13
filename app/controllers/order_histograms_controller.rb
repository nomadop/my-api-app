class OrderHistogramsController < ApplicationController
  def list
    ids = JSON.parse(request.raw_post)
    result = OrderHistogram.where(item_nameid: ids)
    render json: result.as_json(except: [:id, :created_at, :updated_at])
  end

  def show
    @item_nameid = params[:id]
    render layout: 'vue'
  end

  def json
    @item_nameid = params[:id]
    render json: OrderHistogram.find_by(item_nameid: @item_nameid).as_json
  end

  def history
    @item_nameid = params[:id]
    render json: OrderHistogramHistory
      .where(item_nameid: @item_nameid)
      .where.not(created_at: nil)
      .order(:created_at)
      .as_json(except: :id)
  end

  end
end
