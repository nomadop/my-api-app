class AutoSellAndGrindJob < ApplicationJob
  queue_as :quick_sell

  EXIST_MESSAGE = '您已上架该物品并正等待确认。请确认或撤下现有的上架物品。'
  NOT_EXIST_MESSAGE = '指定的物品不再存在于您的库存，或者不允许在社区市场交易该物品。'

  def perform(id)
    @asset = InventoryAsset.find(id)
    @asset.auto_sell_and_grind
  end

  rescue_from(RestClient::BadGateway) do |e|
    result = JSON.parse(e.http_body)
    if result['message'] == EXIST_MESSAGE || result['message'] == NOT_EXIST_MESSAGE
      puts EXIST_MESSAGE
      clean_job_concurrence
    else
      @asset.account.refresh
      retry_job
    end
  end

  rescue_from(ActiveRecord::RecordNotFound) do
    clean_job_concurrence
  end
end
