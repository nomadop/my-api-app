class QuickSellAssetJob < ApplicationJob
  queue_as :quick_sell

  EXIST_MESSAGE = '您已上架该物品并正等待确认。请确认或撤下现有的上架物品。'

  def perform(id)
    InventoryAsset.find(id).quick_sell
  end

  rescue_from(RestClient::BadGateway) do |e|
    result = JSON.parse(e.http_body)
    if result['message'] == EXIST_MESSAGE
      puts EXIST_MESSAGE
      clean_job_concurrence
    else
      retry_job
    end
  end
end
