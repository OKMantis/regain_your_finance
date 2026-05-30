require "test_helper"

class SpendingCategoriesControllerTest < ActionDispatch::IntegrationTest
  test "POST /spending_categories creates a category and redirects (html)" do
    assert_difference "SpendingCategory.count", 1 do
      post spending_categories_path,
           params: { spending_category: { name: "Coffee", weekly_target_euros: "20", monthly_target_euros: "80" } }
    end
    assert_redirected_to spending_path
    cat = SpendingCategory.last
    assert_equal "Coffee", cat.name
    assert_equal 2000, cat.weekly_target_cents
    assert_equal 8000, cat.monthly_target_cents
  end

  test "POST /spending_categories with turbo_stream responds with stream" do
    post spending_categories_path,
         params: { spending_category: { name: "Groceries" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "PATCH /spending_categories/:id updates the category" do
    cat = SpendingCategory.create!(name: "Drinks")
    patch spending_category_path(cat),
          params: { spending_category: { name: "Coffee & Tea", weekly_target_euros: "15" } }
    assert_redirected_to spending_path
    assert_equal "Coffee & Tea", cat.reload.name
    assert_equal 1500, cat.reload.weekly_target_cents
  end

  test "DELETE /spending_categories/:id destroys category and entries" do
    cat = SpendingCategory.create!(name: "Misc")
    cat.spending_entries.create!(amount_cents: 500, spent_on: Date.today)
    assert_difference ["SpendingCategory.count", "SpendingEntry.count"], -1 do
      delete spending_category_path(cat)
    end
    assert_redirected_to spending_path
  end

  test "POST with invalid name does not create category" do
    assert_no_difference "SpendingCategory.count" do
      post spending_categories_path,
           params: { spending_category: { name: "" } }
    end
    assert_redirected_to spending_path
  end
end
