class SpendingController < ApplicationController
  def index
    @yearly     = params[:period] == "yearly"
    @categories = SpendingCategory.order(:name)

    today       = Date.today
    week_range  = today.beginning_of_week..today.end_of_week
    month_range = today.beginning_of_month..today.end_of_month

    @weekly_totals  = SpendingEntry.where(spent_on: week_range)
                                   .group(:spending_category_id)
                                   .sum(:amount_cents)
    @monthly_totals = SpendingEntry.where(spent_on: month_range)
                                   .group(:spending_category_id)
                                   .sum(:amount_cents)

    if @yearly
      year_range     = today.beginning_of_year..today.end_of_year
      @yearly_totals = SpendingEntry.where(spent_on: year_range)
                                    .group(:spending_category_id)
                                    .sum(:amount_cents)
    end

    @entries_by_category = SpendingEntry.where(spent_on: month_range)
                                        .order(spent_on: :desc)
                                        .group_by(&:spending_category_id)
  end
end
