class SpendingCategory < ApplicationRecord
  has_many :spending_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :weekly_target_cents,  numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :monthly_target_cents, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  # Returns an array of week buckets for the given month.
  # Each bucket: { start: Date, end: Date, spent_cents: Integer, target_cents: Integer|nil }
  # Week boundary: Monday (Rails default / ISO week).
  def weeks_in_month(date = Date.today)
    month_start = date.beginning_of_month
    month_end   = date.end_of_month
    buckets     = []
    cursor      = month_start.beginning_of_week

    while cursor <= month_end
      wk_start = [cursor, month_start].max
      wk_end   = [cursor.end_of_week, month_end].min
      spent    = spending_entries.where(spent_on: wk_start..wk_end).sum(:amount_cents)
      buckets << { start: wk_start, end: wk_end, spent_cents: spent, target_cents: weekly_target_cents }
      cursor += 7
    end

    buckets
  end
end
