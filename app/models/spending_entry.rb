class SpendingEntry < ApplicationRecord
  belongs_to :spending_category

  validates :amount_cents, presence: true,
                           numericality: { greater_than_or_equal_to: 0,
                                           less_than_or_equal_to: 10_000_000 }
  validates :spent_on,     presence: true
  validates :description,  length: { maximum: 255 }, allow_nil: true

  def amount_euros
    amount_cents / 100.0
  end
end
