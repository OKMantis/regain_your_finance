require "test_helper"

class SpendingEntryTest < ActiveSupport::TestCase
  def category
    @category ||= SpendingCategory.create!(name: "Groceries")
  end

  def valid_entry
    SpendingEntry.new(spending_category: category, amount_cents: 1500, spent_on: Date.today)
  end

  test "valid with required fields" do
    assert valid_entry.valid?
  end

  test "invalid without amount_cents" do
    e = valid_entry
    e.amount_cents = nil
    assert_not e.valid?
  end

  test "invalid with negative amount_cents" do
    e = valid_entry
    e.amount_cents = -1
    assert_not e.valid?
  end

  test "invalid without spent_on" do
    e = valid_entry
    e.spent_on = nil
    assert_not e.valid?
  end

  test "invalid without spending_category" do
    e = valid_entry
    e.spending_category = nil
    assert_not e.valid?
  end

  test "description is optional" do
    e = valid_entry
    e.description = nil
    assert e.valid?
  end

  test "amount_euros returns decimal euros" do
    e = valid_entry
    e.amount_cents = 1550
    assert_equal 15.5, e.amount_euros
  end
end
