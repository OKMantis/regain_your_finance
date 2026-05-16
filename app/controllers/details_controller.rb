class DetailsController < ApplicationController
  def index
    @yearly = params[:period] == "yearly"
    @income_items        = LineItem.income.order(:name)
    @housing_items       = LineItem.housing.order(:name)
    @subscription_items  = LineItem.subscriptions.order(:name)
    @food_items          = LineItem.food_entertainment.order(:name)
  end
end
