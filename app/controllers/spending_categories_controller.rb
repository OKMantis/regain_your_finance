class SpendingCategoriesController < ApplicationController
  before_action :set_category, only: [ :update, :destroy ]

  def create
    @category = SpendingCategory.new(category_params)

    if @category.save
      @yearly = params[:spending_category][:period] == "yearly"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to spending_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to spending_path }
        format.html { redirect_to spending_path }
      end
    end
  end

  def update
    @yearly = params[:spending_category][:period] == "yearly"

    if @category.update(category_params)
      today = Date.today
      week_range  = today.beginning_of_week..today.end_of_week
      month_range = today.beginning_of_month..today.end_of_month

      @weekly_total  = @category.spending_entries.where(spent_on: week_range).sum(:amount_cents)
      @monthly_total = @category.spending_entries.where(spent_on: month_range).sum(:amount_cents)
      @yearly_total  = @yearly ? @category.spending_entries.where(spent_on: today.beginning_of_year..today.end_of_year).sum(:amount_cents) : nil
      @entries       = @category.spending_entries.where(spent_on: month_range).order(spent_on: :desc)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to spending_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to spending_path }
        format.html { redirect_to spending_path }
      end
    end
  end

  def destroy
    @category.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to spending_path }
    end
  end

  private

  def set_category
    @category = SpendingCategory.find(params[:id])
  end

  def category_params
    raw = params.require(:spending_category).permit(:name, :weekly_target_euros, :monthly_target_euros, :period)
    attrs = { name: raw[:name] }
    attrs[:weekly_target_cents]  = euros_to_cents(raw[:weekly_target_euros])
    attrs[:monthly_target_cents] = euros_to_cents(raw[:monthly_target_euros])
    attrs
  end

  def euros_to_cents(value)
    return nil if value.blank?
    (value.to_f * 100).round
  end
end
