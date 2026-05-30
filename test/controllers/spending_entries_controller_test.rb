require "test_helper"

class SpendingEntriesControllerTest < ActionDispatch::IntegrationTest
  def category
    @category ||= SpendingCategory.create!(name: "Groceries", weekly_target_cents: 5000, monthly_target_cents: 20000)
  end

  test "POST /spending_entries creates entry with today's date" do
    assert_difference "SpendingEntry.count", 1 do
      post spending_entries_path,
           params: { spending_entry: { spending_category_id: category.id, amount_euros: "12.50", description: "Carrots" } }
    end
    assert_redirected_to spending_path
    entry = SpendingEntry.last
    assert_equal 1250, entry.amount_cents
    assert_equal Date.today, entry.spent_on
    assert_equal "Carrots", entry.description
  end

  test "POST /spending_entries with turbo_stream responds with stream" do
    post spending_entries_path,
         params: { spending_entry: { spending_category_id: category.id, amount_euros: "5.00" } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "POST /spending_entries with blank amount does not create entry" do
    assert_no_difference "SpendingEntry.count" do
      post spending_entries_path,
           params: { spending_entry: { spending_category_id: category.id, amount_euros: "" } }
    end
    assert_redirected_to spending_path
  end

  test "DELETE /spending_entries/:id destroys the entry" do
    entry = SpendingEntry.create!(spending_category: category, amount_cents: 800, spent_on: Date.today)
    assert_difference "SpendingEntry.count", -1 do
      delete spending_entry_path(entry)
    end
    assert_redirected_to spending_path
  end

  test "DELETE /spending_entries/:id with turbo_stream responds with stream" do
    entry = SpendingEntry.create!(spending_category: category, amount_cents: 800, spent_on: Date.today)
    delete spending_entry_path(entry),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end
end
