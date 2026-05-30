class SpendingEntry < ApplicationRecord
  belongs_to :spending_category

  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :spent_on,     presence: true

  def amount_euros
    amount_cents / 100.0
  end
end
