class SendItemsJob < ApplicationJob
  queue_as :default

  def perform(account_id, target_id)
    account = Account.find(account_id)
    account.asf('2fano')
    account.reload_inventory
    account.send_items(Account.find(target_id))
    account.asf('2faok')
  end
end
