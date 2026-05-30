require "test_helper"

class SpendingCategoriesControllerTest < ActionDispatch::IntegrationTest
  test "POST /spending_categories creates a category with weekly target" do
    assert_difference "SpendingCategory.count", 1 do
      post spending_categories_path,
           params: { spending_category: { name: "Coffee", target_euros: "20", target_period: "weekly" } }
    end
    assert_redirected_to spending_path
    cat = SpendingCategory.last
    assert_equal "Coffee", cat.name
    assert_equal 2000, cat.weekly_target_cents
    assert_nil cat.monthly_target_cents
  end

  test "POST /spending_categories creates a category with monthly target" do
    assert_difference "SpendingCategory.count", 1 do
      post spending_categories_path,
           params: { spending_category: { name: "Dining", target_euros: "80", target_period: "monthly" } }
    end
    assert_redirected_to spending_path
    cat = SpendingCategory.last
    assert_equal 8000, cat.monthly_target_cents
    assert_nil cat.weekly_target_cents
  end

  test "POST /spending_categories creates a category with no target" do
    assert_difference "SpendingCategory.count", 1 do
      post spending_categories_path,
           params: { spending_category: { name: "Misc" } }
    end
    cat = SpendingCategory.last
    assert_nil cat.weekly_target_cents
    assert_nil cat.monthly_target_cents
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
          params: { spending_category: { name: "Coffee & Tea", target_euros: "15", target_period: "weekly" } }
    assert_redirected_to spending_path
    assert_equal "Coffee & Tea", cat.reload.name
    assert_equal 1500, cat.reload.weekly_target_cents
    assert_nil cat.reload.monthly_target_cents
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

  test "PATCH /spending_categories/:id with turbo_stream responds with stream" do
    cat = SpendingCategory.create!(name: "Fuel")
    patch spending_category_path(cat),
          params: { spending_category: { name: "Fuel Updated", target_euros: "25", target_period: "weekly" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal "Fuel Updated", cat.reload.name
  end

  test "PATCH /spending_categories/:id with invalid name redirects" do
    cat = SpendingCategory.create!(name: "Valid")
    patch spending_category_path(cat),
          params: { spending_category: { name: "" } }
    assert_redirected_to spending_path
    assert_equal "Valid", cat.reload.name
  end

  test "DELETE /spending_categories/:id with turbo_stream responds with stream" do
    cat = SpendingCategory.create!(name: "ToDelete")
    assert_difference "SpendingCategory.count", -1 do
      delete spending_category_path(cat),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "PATCH passes period=yearly flag through" do
    cat = SpendingCategory.create!(name: "Yearly Cat")
    patch spending_category_path(cat),
          params: { spending_category: { name: "Yearly Cat", period: "yearly" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end
end
