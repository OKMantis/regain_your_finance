class SpendingCategoriesController < ApplicationController
  before_action :set_category, only: [ :update, :destroy ]

  def create
    @category = SpendingCategory.new(category_params)
    @yearly   = params[:spending_category][:period] == "yearly"

    if @category.save
      @categories = SpendingCategory.order(:name)
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
    raw = params.require(:spending_category).permit(:name, :target_euros, :target_period, :period)
    cents = euros_to_cents(raw[:target_euros])
    attrs = { name: raw[:name] }
    if cents.nil?
      attrs[:weekly_target_cents]  = nil
      attrs[:monthly_target_cents] = nil
    elsif raw[:target_period] == "monthly"
      attrs[:monthly_target_cents] = cents
      attrs[:weekly_target_cents]  = (cents / 4.0).round
    else
      attrs[:weekly_target_cents]  = cents
      attrs[:monthly_target_cents] = (cents * 4.0).round
    end
    attrs
  end

  def euros_to_cents(value)
    return nil if value.blank?
    (value.to_f * 100).round
  end
end
