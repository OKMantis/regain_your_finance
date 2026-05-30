class SpendingEntriesController < ApplicationController
  def create
    raw_amount = params.dig(:spending_entry, :amount_euros)
    if raw_amount.blank?
      respond_to do |format|
        format.turbo_stream { redirect_to spending_path }
        format.html { redirect_to spending_path }
      end
      return
    end

    @entry = SpendingEntry.new(entry_params)
    @entry.spent_on = Date.today
    @yearly = params[:spending_entry][:period] == "yearly"

    if @entry.save
      @category   = @entry.spending_category
      @categories = SpendingCategory.order(:name)
      compute_category_totals
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
    @entry    = SpendingEntry.find(params[:id])
    @category = @entry.spending_category
    @yearly   = params[:period] == "yearly"
    @entry.destroy
    compute_category_totals
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to spending_path }
    end
  end

  private

  def entry_params
    raw = params.require(:spending_entry).permit(:spending_category_id, :amount_euros, :description, :period)
    {
      spending_category_id: raw[:spending_category_id],
      amount_cents:         (raw[:amount_euros].to_f * 100).round,
      description:          raw[:description].presence
    }
  end

  def compute_category_totals
    today       = Date.today
    week_range  = today.beginning_of_week..today.end_of_week
    month_range = today.beginning_of_month..today.end_of_month

    @weekly_total  = @category.spending_entries.where(spent_on: week_range).sum(:amount_cents)
    @monthly_total = @category.spending_entries.where(spent_on: month_range).sum(:amount_cents)
    @yearly_total  = @yearly ? @category.spending_entries.where(spent_on: today.beginning_of_year..today.end_of_year).sum(:amount_cents) : nil
    @entries       = @category.spending_entries.where(spent_on: month_range).order(spent_on: :desc)
  end
end
