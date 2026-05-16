class LineItemsController < ApplicationController
  def update
    @line_item = LineItem.find(params[:id])
    if @line_item.update(line_item_params)
      redirect_to details_path(period: params[:period]), status: :see_other
    else
      redirect_to details_path(period: params[:period]), status: :see_other, alert: "Could not save."
    end
  end

  private

  def line_item_params
    params.require(:line_item).permit(:amount_cents, :billing_period, :name)
  end
end
