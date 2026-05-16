module ApplicationHelper
  def format_euros(cents, period: nil)
    euros = (cents.abs / 100.0).round
    formatted = number_to_currency(euros, unit: "€", separator: ",", delimiter: ".", precision: 0, format: "%u%n")
    period ? "#{formatted}/#{period}" : formatted
  end

  def period_label(yearly)
    yearly ? "yr" : "mo"
  end

  def amount_for(item, yearly:)
    cents = yearly ? item.amount_cents_monthly * 12 : item.amount_cents_monthly
    format_euros(cents)
  end
end
