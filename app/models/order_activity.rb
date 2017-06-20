class OrderActivity < ApplicationRecord
  scope :buy, -> { where('content like ?', '%手中购买了这件物品') }
  scope :sell, -> { where('content like ?', '%的价格出售了这件物品') }
  scope :create_order, -> { where('content like ?', '%提交了%份%的订购单') }
  scope :with_in, ->(duration) { where('created_at > ?', duration.ago) }
  scope :url_avatar, -> { where('user1_avatar ') }

  def buy?
    content =~ /手中购买了这件物品$/
  end

  def create_order?
    content =~ /提交了.*份.*的订购单$/
  end

  def find_user1
    result = Steam.find_user(user1_name, user1_avatar)
    return if result.nil?

    steam_user = SteamUser.create(result)
    steam_user.load_profile_data
    steam_user.set_nickname('市场订购宝珠') if create_order?
    steam_user.set_nickname('市场购买宝珠') if buy?
  end
end
