class PropertiesController < ApplicationController
  def index
    @yearly = params[:period] == "yearly"
    @properties = Property.includes(:line_items, :property_expenses).all
    @total_net_monthly = @properties.sum(&:net_cents_monthly)
  end
end
