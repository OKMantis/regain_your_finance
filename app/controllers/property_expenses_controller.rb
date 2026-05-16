class PropertyExpensesController < ApplicationController
  def update
    @expense = PropertyExpense.find(params[:id])
    if @expense.update(expense_params)
      redirect_to properties_path(period: params[:period]), status: :see_other
    else
      redirect_to properties_path(period: params[:period]), status: :see_other, alert: "Could not save."
    end
  end

  private

  def expense_params
    params.require(:property_expense).permit(:amount_cents, :billing_period, :name)
  end
end
