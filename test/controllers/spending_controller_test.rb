require "test_helper"

class SpendingControllerTest < ActionDispatch::IntegrationTest
  test "GET /spending renders successfully with no categories" do
    get spending_path
    assert_response :success
  end

  test "GET /spending renders categories with weekly and monthly totals" do
    cat = SpendingCategory.create!(name: "Coffee", weekly_target_cents: 2000, monthly_target_cents: 8000)
    SpendingEntry.create!(spending_category: cat, amount_cents: 500, spent_on: Date.today)

    get spending_path
    assert_response :success
    assert_select "div#spending_categories_list"
    assert_select "div#spending_category_stats_#{cat.id}"
  end

  test "GET /spending with period=yearly responds successfully" do
    get spending_path, params: { period: "yearly" }
    assert_response :success
  end
end
