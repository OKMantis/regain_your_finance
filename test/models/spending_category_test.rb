require "test_helper"

class SpendingCategoryTest < ActiveSupport::TestCase
  def valid_category
    SpendingCategory.new(name: "Groceries")
  end

  test "valid with name only" do
    assert valid_category.valid?
  end

  test "invalid without name" do
    cat = valid_category
    cat.name = nil
    assert_not cat.valid?
    assert_includes cat.errors[:name], "can't be blank"
  end

  test "invalid with duplicate name" do
    SpendingCategory.create!(name: "Coffee")
    dup = SpendingCategory.new(name: "Coffee")
    assert_not dup.valid?
    assert_includes dup.errors[:name], "has already been taken"
  end

  test "weekly_target_cents must be non-negative if present" do
    cat = valid_category
    cat.weekly_target_cents = -1
    assert_not cat.valid?
  end

  test "weekly_target_cents can be nil" do
    cat = valid_category
    cat.weekly_target_cents = nil
    assert cat.valid?
  end

  test "monthly_target_cents must be non-negative if present" do
    cat = valid_category
    cat.monthly_target_cents = -1
    assert_not cat.valid?
  end

  test "has many spending_entries destroyed on delete" do
    cat = SpendingCategory.create!(name: "Groceries")
    cat.spending_entries.create!(amount_cents: 1000, spent_on: Date.today)
    assert_difference "SpendingEntry.count", -1 do
      cat.destroy
    end
  end

  test "weeks_in_month returns correct week buckets" do
    cat = SpendingCategory.create!(name: "Test", weekly_target_cents: 5000)
    # Create entries on May 5 (week 1) and May 12 (week 2)
    cat.spending_entries.create!(amount_cents: 2000, spent_on: Date.new(2026, 5, 5))
    cat.spending_entries.create!(amount_cents: 3000, spent_on: Date.new(2026, 5, 12))

    weeks = cat.weeks_in_month(Date.new(2026, 5, 1))
    assert weeks.length >= 4
    total_spent = weeks.sum { |w| w[:spent_cents] }
    assert_equal 5000, total_spent
  end
end
