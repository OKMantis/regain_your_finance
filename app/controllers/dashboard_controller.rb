class DashboardController < ApplicationController
  def index
    @yearly = params[:period] == "yearly"

    @income_monthly  = LineItem.income.sum(:amount_cents_monthly)
    @personal_expense_monthly = LineItem.where.not(category: :income).sum(:amount_cents_monthly)
    @property_expense_monthly = PropertyExpense.sum(:amount_cents_monthly)
    @total_expense_monthly = @personal_expense_monthly + @property_expense_monthly
    @savings_monthly = @income_monthly - @total_expense_monthly
    @savings_rate = @income_monthly > 0 ? (@savings_monthly.to_f / @income_monthly * 100).round(1) : 0

    @income_items = LineItem.income.order(:name)
    @expense_by_category = LineItem.where.not(category: :income)
                                   .group(:category)
                                   .sum(:amount_cents_monthly)
  end
end
