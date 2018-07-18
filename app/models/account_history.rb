require 'axlsx'

class AccountHistory < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :account

  scope :belongs, ->(account) { where(account: account) }
  scope :since, ->(time) { where('date > ?', time) }
  scope :with_in, ->(duration) { since(duration.ago) }
  scope :between, ->(from, to) { where(date: (from..to)) }
  scope :with_item, ->(item) { where("items->>0 = '#{item}'") }
  scope :without_item, ->(item) { where.not("items->>0 = '#{item}'") }
  scope :market, -> { with_item('Steam 社区市场') }
  scope :non_market, -> { without_item('Steam 社区市场') }
  scope :wallet, -> { where('items->>0 like ?', '已购买%钱包资金') }
  scope :non_wallet, -> { where.not('items->>0 like ?', '已购买%钱包资金') }
  scope :income, -> { where('change > 0') }
  scope :expense, -> { where('change < 0') }
  scope :gift, -> { where(type: '礼物购买') }
  scope :purchase, -> { where('type like ?', '购买%') }
  scope :refund, -> { where(type: '退款') }
  scope :payment, ->(payment) { where(payment: payment) }
  scope :refundable, -> { purchase.with_in(2.weeks) }
  scope :refunded, -> { where(refunded: true) }
  scope :not_refunded, -> { where(refunded: false) }
  scope :group_by_month, -> { group('CAST(date_trunc(\'month\', date) AS DATE)') }

  class << self
    def total
      sum(:total)
    end

    def total_change
      sum(:change)
    end

    def total_spent
     purchase.expense.payment('钱包').total_change + refund.income.total_change + gift.expense.total_change
    end

    def purchase_without_refund
      not_refunded_purchase.expense.payment('钱包')
    end

    def purchase_report
      Axlsx::Package.new do |package|
        package.workbook.add_worksheet(name: 'Purchase Without Refund') do |sheet|
          sheet.add_row(%w|Game Price|)
          purchase_without_refund.each do |history|
            sheet.add_row([history.items.first, Utility.format_price(history.total)])
          end
          sheet.add_row(['Sum', Utility.format_price(purchase_without_refund.sum(&:total))])
        end
        package.serialize('purchases.xlsx')
      end
      true
    end

    def expense_report
      Axlsx::Package.new do |package|
        package.workbook.add_worksheet(name: 'Purchased') do |sheet|
          sheet.add_row(%w|Game Price|)
          purchase.expense.payment('钱包').find_each do |history|
            sheet.add_row([history.items.first, Utility.format_price(history.total)])
          end
          sheet.add_row(['Sum', Utility.format_price(purchase.expense.payment('钱包').total)])
        end
        package.workbook.add_worksheet(name: 'Refund') do |sheet|
          sheet.add_row(%w|Game Price|)
          refund.income.find_each do |history|
            sheet.add_row([history.items.first, Utility.format_price(history.total)])
          end
          sheet.add_row(['Sum', Utility.format_price(refund.income.total)])
        end
        package.workbook.add_worksheet(name: 'Gift') do |sheet|
          sheet.add_row(%w|Game Price SendTo|)
          gift.expense.find_each do |history|
            sheet.add_row([history.items.first, Utility.format_price(history.total), history.items.last])
          end
          sheet.add_row(['Sum', Utility.format_price(gift.expense.total)])
        end
        package.serialize('expenses.xlsx')
      end
      true
    end
  end

  def formatted_date
    date.getlocal('+08:00').strftime('%y-%m-%d')
  end

  def item_name
    items[0]
  end
end
