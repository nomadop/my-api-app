require 'axlsx'

class AccountHistory < ApplicationRecord
  self.inheritance_column = nil

  scope :since, ->(time) { where('date > ?', time) }
  scope :with_in, ->(duration) { since(duration.ago) }
  scope :between, ->(from, to) { where(date: (from..to)) }
  scope :market, -> { where("items->>0 = 'Steam 社区市场'") }
  scope :wallet, -> { where('items->>0 like ?', '已购买%钱包资金') }
  scope :non_wallet, -> { where.not('items->>0 like ?', '已购买%钱包资金') }
  scope :income, -> { where('change > 0') }
  scope :expense, -> { where('change < 0') }
  scope :gift, -> { where(type: '礼物购买') }
  scope :purchase, -> { where(type: '购买') }
  scope :refund, -> { where(type: '退款') }
  scope :payment, ->(payment) { where(payment: payment) }

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

    def expense_report
      Axlsx::Package.new do |package|
        package.workbook.add_worksheet(name: 'Purchased') do |sheet|
          sheet.add_row(%w|Game Price|)
          purchase.expense.payment('钱包').find_each do |history|
            sheet.add_row([history.items.first, Utility.format_currency(history.total)])
          end
          sheet.add_row(['Sum', Utility.format_currency(purchase.expense.payment('钱包').total)])
        end
        package.workbook.add_worksheet(name: 'Refund') do |sheet|
          sheet.add_row(%w|Game Price|)
          refund.income.find_each do |history|
            sheet.add_row([history.items.first, Utility.format_currency(history.total)])
          end
          sheet.add_row(['Sum', Utility.format_currency(refund.income.total)])
        end
        package.workbook.add_worksheet(name: 'Gift') do |sheet|
          sheet.add_row(%w|Game Price SendTo|)
          gift.expense.find_each do |history|
            sheet.add_row([history.items.first, Utility.format_currency(history.total), history.items.last])
          end
          sheet.add_row(['Sum', Utility.format_currency(gift.expense.total)])
        end
        package.serialize('expenses.xlsx')
      end
      true
    end
  end
end
