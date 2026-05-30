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

  def progress_bar_color(spent_cents, target_cents)
    return nil if target_cents.nil? || target_cents.zero?
    pct = spent_cents * 100.0 / target_cents
    if pct < 80
      "bg-emerald-500"
    elsif pct < 100
      "bg-amber-500"
    else
      "bg-red-500"
    end
  end

  def progress_bar_width(spent_cents, target_cents)
    return "0%" if target_cents.nil? || target_cents.zero?
    pct = [ spent_cents * 100.0 / target_cents, 100 ].min
    "#{pct.round(1)}%"
  end
end
