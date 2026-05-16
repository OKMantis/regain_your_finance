class Property < ApplicationRecord
  has_many :line_items, dependent: :destroy
  has_many :property_expenses, dependent: :destroy

  validates :name, presence: true
  validates :ownership_percentage, presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }

  def income_cents_monthly
    line_items.income.sum(:amount_cents_monthly)
  end

  def expenses_cents_monthly
    property_expenses.sum(:amount_cents_monthly)
  end

  def net_cents_monthly
    income_cents_monthly - expenses_cents_monthly
  end
end
