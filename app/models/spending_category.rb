class SpendingCategory < ApplicationRecord
  has_many :spending_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :weekly_target_cents,  numericality: { greater_than_or_equal_to: 0,
                                                    less_than_or_equal_to: 10_000_000,
                                                    allow_nil: true }
  validates :monthly_target_cents, numericality: { greater_than_or_equal_to: 0,
                                                    less_than_or_equal_to: 10_000_000,
                                                    allow_nil: true }

  # Returns an array of week buckets for the given month.
  # Each bucket: { start: Date, end: Date, spent_cents: Integer, target_cents: Integer|nil }
  # Week boundary: Monday (Rails default / ISO week).
  #
  # Pass preloaded_entries: (an already-fetched array of SpendingEntry records) to
  # avoid issuing a SQL query per week bucket — the weekly totals are then computed
  # in Ruby from the preloaded array.
  def weeks_in_month(date = Date.today, preloaded_entries: nil)
    month_start = date.beginning_of_month
    month_end   = date.end_of_month
    buckets     = []
    cursor      = month_start.beginning_of_week

    while cursor <= month_end
      wk_start = [cursor, month_start].max
      wk_end   = [cursor.end_of_week, month_end].min
      spent = if preloaded_entries
        preloaded_entries
          .select { |e| e.spent_on >= wk_start && e.spent_on <= wk_end }
          .sum(&:amount_cents)
      else
        spending_entries.where(spent_on: wk_start..wk_end).sum(:amount_cents)
      end
      buckets << { start: wk_start, end: wk_end, spent_cents: spent, target_cents: weekly_target_cents }
      cursor += 7
    end

    buckets
  end
end
