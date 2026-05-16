class PropertyExpense < ApplicationRecord
  belongs_to :property

  enum :category, {
    mortgage: 0,
    insurance: 1,
    tax: 2,
    community: 3,
    contingency: 4
  }

  enum :billing_period, {
    monthly: 0,
    yearly: 1,
    quarterly: 2,
    bi_weekly: 3,
    weekly: 4
  }

  validates :name, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :billing_period, presence: true

  before_save :compute_monthly_amount

  MONTHLY_DIVISORS = {
    "monthly"    => 1.0,
    "yearly"     => 12.0,
    "quarterly"  => 3.0,
    "bi_weekly"  => 0.5,
    "weekly"     => 1.0 / 4.333
  }.freeze

  def amount_euros
    amount_cents / 100.0
  end

  def amount_monthly_euros
    amount_cents_monthly / 100.0
  end

  def amount_yearly_euros
    (amount_cents_monthly * 12) / 100.0
  end

  private

  def compute_monthly_amount
    divisor = MONTHLY_DIVISORS[billing_period] || 1.0
    self.amount_cents_monthly = (amount_cents / divisor).round
  end
end
