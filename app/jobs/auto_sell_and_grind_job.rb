class AutoSellAndGrindJob < ApplicationJob
  queue_as :quick_sell

  EXIST_MESSAGE = '您已上架该物品并正等待确认。请确认或撤下现有的上架物品。'
  NOT_EXIST_MESSAGE = '指定的物品不再存在于您的库存，或者不允许在社区市场交易该物品。'
  EXPIRED_MESSAGE = '您选择的项目已过期或已不存在。'
  NETWORK_ERROR_MESSAGE = '与网络连接时出现错误。请稍后再试。'

  def perform(id)
    @asset = InventoryAsset.find(id)
    @asset.auto_sell_and_grind
  end

  rescue_from(RestClient::BadGateway, RestClient::BadRequest) do |e|
    result = JSON.parse(e.http_body)
    if [EXIST_MESSAGE, NOT_EXIST_MESSAGE, EXPIRED_MESSAGE].include?(result['message'])
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

  rescue_from(RestClient::InternalServerError) do
    clean_job_concurrence
  end

  rescue_from(RuntimeError) do |e|
    clean_job_concurrence
    raise e
  end
end
