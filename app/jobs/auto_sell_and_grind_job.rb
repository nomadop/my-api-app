class AutoSellAndGrindJob < ApplicationJob
  queue_as :quick_sell
  rescue_from RestClient::BadGateway, with: :handle_error
  rescue_from RestClient::BadRequest, with: :handle_error

  EXIST_MESSAGE = '您已上架该物品并正等待确认。请确认或撤下现有的上架物品。'
  NOT_EXIST_MESSAGE = '指定的物品不再存在于您的库存，或者不允许在社区市场交易该物品。'
  EXPIRED_MESSAGE = '您选择的项目已过期或已不存在。'
  NETWORK_ERROR_MESSAGE = '与网络连接时出现错误。请稍后再试。'
  RETRY_MESSAGE = '您的物品在上架时出现问题。请刷新页面并重试。'

  def perform(id)
    @asset = InventoryAsset.find(id)
    result = @asset.auto_sell_and_grind
    if result&.[]('message') === RETRY_MESSAGE
      retry_job
    end
  end

  def handle_error(exception)
    result = JSON.parse(exception.http_body)
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
